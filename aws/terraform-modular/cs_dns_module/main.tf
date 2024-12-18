resource "random_string" "gslb_domain_suffix" {
  count   = var.app_count
  length  = 3
  special = false
  upper   = false
  number  = false
}


locals {
  # app list is an array of app values, inside an array of apps, inside an array per bigip 
  # like this: [[bigip0 [app0], [app1]], [bigip1 [app0], [app1]]
  #Parse the subs list to find the subscription for the parent DNS zone.
  dns_subs = [for subs in jsondecode(data.local_file.f5cs_get_subs_list_response.content).subscriptions :
    subs.subscription_id if subs.service_instance_name == "archf5.com"
  ]
  gslb_zones = [for index, each_app in var.app_list[0] :
    format("gslb-%s.%s", random_string.gslb_domain_suffix[index].result, each_app[1])
  ]
  mem_acc_id = [for mem in jsondecode(data.local_file.f5cs_member_info_response.content).memberships :
    mem.account_id if mem.account_name == "F5 DNS Beacon EAP and Bot"
  ]
  app_list = [
    for each_bigip in var.app_list : [
      for index, each_app in each_bigip : concat(each_app, [format("%s.gslb-%s.%s", each_app[0], random_string.gslb_domain_suffix[index].result, each_app[1])])
    ]
  ]
}


resource "null_resource" "cs_login" {

  provisioner "local-exec" {
    command = "curl -k -X POST -H 'Content-type: application/json' --data-raw '{ \"username\": \"${var.f5cs_user}\",\"password\": \"${var.f5cs_pass}\" }' https://api.cloudservices.f5.com/v1/svc-auth/login > ${path.module}/dynamic_docs/f5cs1_login_response.json"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "rm -f ${path.module}/dynamic_docs/f5cs1_login_response.json"
  }
}


data "local_file" "f5cs_login_response" {
  filename   = "${path.module}/dynamic_docs/f5cs1_login_response.json"
  depends_on = [null_resource.cs_login]
}


resource "null_resource" "cs_acc_info" {

  provisioner "local-exec" {
    command = "curl -k -H 'Content-type: application/json' -H 'Authorization: Bearer ${jsondecode(data.local_file.f5cs_login_response.content).access_token}' https://api.cloudservices.f5.com/v1/svc-account/user > ${path.module}/dynamic_docs/f5cs2_acc_info.json"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "rm -f ${path.module}/dynamic_docs/f5cs2_acc_info.json"
  }
}


data "local_file" "f5cs_acc_info_response" {
  filename   = "${path.module}/dynamic_docs/f5cs2_acc_info.json"
  depends_on = [null_resource.cs_acc_info]
}


resource "null_resource" "cs_member_info" {

  provisioner "local-exec" {
    command = "curl -k -H 'Content-type: application/json' -H 'Authorization: Bearer ${jsondecode(data.local_file.f5cs_login_response.content).access_token}' https://api.cloudservices.f5.com/v1/svc-account/users/${jsondecode(data.local_file.f5cs_acc_info_response.content).id}/memberships > ${path.module}/dynamic_docs/f5cs3_member_info.json"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "rm -f ${path.module}/dynamic_docs/f5cs3_member_info.json"
  }
}


data "local_file" "f5cs_member_info_response" {
  filename   = "${path.module}/dynamic_docs/f5cs3_member_info.json"
  depends_on = [null_resource.cs_member_info]
}


resource "local_file" "rendered_cs_dns_lb" {
  count      = var.app_count
  depends_on = [data.local_file.f5cs_member_info_response]
  content = templatefile("${path.module}/templates/cs_dns_lb.tpl", {
    gslb_pub_vs_eips_list = var.pub_vs_eips_list[*][count.index]
    gslb_zone             = local.gslb_zones[count.index]
    gslb_zone_a_record    = var.app_list[0][count.index][0]
    account_id            = local.mem_acc_id[0]
  })
  filename = "${path.module}/dynamic_docs/f5cs4_rendered_cs_dns_lb_${count.index}.json"
}


resource "null_resource" "cs_create_dns_lb" {
  count      = var.app_count
  depends_on = [local_file.rendered_cs_dns_lb]

  # Change to POST / PUT depending on whether this is a new subscription (requires POST) or existing (requires PUT). 
  provisioner "local-exec" {
    command = "curl -k -X POST -H 'Content-type: application/json' -H 'Authorization: Bearer ${jsondecode(data.local_file.f5cs_login_response.content).access_token}' --data-binary '@${path.module}/dynamic_docs/f5cs4_rendered_cs_dns_lb_${count.index}.json' https://api.cloudservices.f5.com/v1/svc-subscription/subscriptions > ${path.module}/dynamic_docs/f5cs5_create_dns_lb_${count.index}.json"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "rm -f ${path.module}/dynamic_docs/f5cs5_create_dns_lb_${count.index}.json"
  }
}


data "local_file" "f5cs5_create_dns_lb" {
  count      = var.app_count
  filename   = "${path.module}/dynamic_docs/f5cs5_create_dns_lb_${count.index}.json"
  depends_on = [null_resource.cs_create_dns_lb]
}


# # The following block should be commented out if using PUT in null_resource.cs_create_dns_lb
resource "null_resource" "cs_activate_dns_lb" {
  count      = var.app_count
  depends_on = [local_file.rendered_cs_dns_lb]

  provisioner "local-exec" {
    command = "curl -k -X POST -H 'Content-type: application/json' -H 'Authorization: Bearer ${jsondecode(data.local_file.f5cs_login_response.content).access_token}' https://api.cloudservices.f5.com/v1/svc-subscription/subscriptions/${jsondecode(data.local_file.f5cs5_create_dns_lb[count.index].content).subscription_id}/activate > ${path.module}/dynamic_docs/f5cs6_activate_dns_lb_${count.index}.json"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "rm -f ${path.module}/dynamic_docs/f5cs6_activate_dns_lb_${count.index}.json"
  }
}


#Get subs list to find the subscription for the parent DNS zone.
resource "null_resource" "cs_find_dns_subscription" {
  depends_on = [local_file.rendered_cs_dns_lb]

  provisioner "local-exec" {
    command = "curl -k -H 'Content-type: application/json' -H 'Authorization: Bearer ${jsondecode(data.local_file.f5cs_login_response.content).access_token}' https://api.cloudservices.f5.com/v1/svc-subscription/subscriptions?account_id=${local.mem_acc_id[0]} > ${path.module}/dynamic_docs/f5cs7_get_subs_list.json"
  } 

  provisioner "local-exec" {
    when    = destroy
    command = "rm -f ${path.module}/dynamic_docs/f5cs7_get_subs_list.json"
  }
}


data "local_file" "f5cs_get_subs_list_response" {
  filename   = "${path.module}/dynamic_docs/f5cs7_get_subs_list.json"
  depends_on = [null_resource.cs_find_dns_subscription]
}


resource "local_file" "rendered_cs_dns_cname" {
  depends_on = [data.local_file.f5cs_member_info_response]
  content = templatefile("${path.module}/templates/cs_dns_cname.tpl", {
    gslb_zones          = local.gslb_zones
    gslb_zone_a_records = var.app_list[0]
  })
  filename = "${path.module}/dynamic_docs/f5cs8_rendered_cs_cname.json"
}


resource "null_resource" "cs_create_cname_in_parent_zone" {
  depends_on = [local_file.rendered_cs_dns_cname]

  provisioner "local-exec" {
    command = "curl -k -X PUT -H 'Content-type: application/json' -H 'Authorization: Bearer ${jsondecode(data.local_file.f5cs_login_response.content).access_token}' --data-binary '@${path.module}/dynamic_docs/f5cs8_rendered_cs_cname.json' https://api.cloudservices.f5.com/v1/svc-subscription/subscriptions/${local.dns_subs[0]} > ${path.module}/dynamic_docs/f5cs9_create_dns_cname_response.json"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "rm -f ${path.module}/dynamic_docs/f5cs9_create_dns_cname_response.json"
  }
}
