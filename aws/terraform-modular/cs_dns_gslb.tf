resource "null_resource" "cs_login" {
  depends_on = [module.arch_bigip]

  provisioner "local-exec" {
    command = "curl -k -X POST -H 'Content-type: application/json' --data-raw '{ \"username\": \"${ var.f5cs_user }\",\"password\": \"${ var.f5cs_pass }\" }' https://api.cloudservices.f5.com/v1/svc-auth/login > ${path.module}/cloud_services/f5cs1_login_response.json"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "rm -f ${path.module}/cloud_services/f5cs1_login_response.json"
  }
}

data "local_file" "f5cs_login_response" {
  filename   = "${path.module}/cloud_services/f5cs1_login_response.json"
  depends_on = [null_resource.cs_login]
}


# output "z_access_token" {
#   value = jsondecode(data.local_file.f5cs_login_response.content).access_token
# }

resource "null_resource" "cs_acc_info" {

  provisioner "local-exec" {
    command = "curl -k -H 'Content-type: application/json' -H 'Authorization: Bearer ${jsondecode(data.local_file.f5cs_login_response.content).access_token}' https://api.cloudservices.f5.com/v1/svc-account/user > ${path.module}/cloud_services/f5cs2_acc_info.json"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "rm -f ${path.module}/cloud_services/f5cs2_acc_info.json"
  }
}

data "local_file" "f5cs_acc_info_response" {
  filename   = "${path.module}/cloud_services/f5cs2_acc_info.json"
  depends_on = [null_resource.cs_acc_info]
}

# output "z_acc_info" {
#   value = jsondecode(data.local_file.f5cs_acc_info_response.content).id
# }

resource "null_resource" "cs_member_info" {

  provisioner "local-exec" {
    command = "curl -k -H 'Content-type: application/json' -H 'Authorization: Bearer ${jsondecode(data.local_file.f5cs_login_response.content).access_token}' https://api.cloudservices.f5.com/v1/svc-account/users/${jsondecode(data.local_file.f5cs_acc_info_response.content).id}/memberships > ${path.module}/cloud_services/f5cs3_member_info.json"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "rm -f ${path.module}/cloud_services/f5cs3_member_info.json"
  }
}

data "local_file" "f5cs_member_info_response" {
  filename   = "${path.module}/cloud_services/f5cs3_member_info.json"
  depends_on = [null_resource.cs_member_info]
}

# output "z_member_info" {
#   value = [ for mem in jsondecode(data.local_file.f5cs_member_info_response.content).memberships :
#     mem.account_id if mem.account_name == "F5 Cloud Services Demo"
#   ]
# }

locals {
    mem_acc_id = [ for mem in jsondecode(data.local_file.f5cs_member_info_response.content).memberships :
    mem.account_id if mem.account_name == "F5 Cloud Services Demo"
  ]
}

resource "local_file" "rendered_cs_dns_lb" {
  count      = length(var.app_list)
  depends_on = [data.local_file.f5cs_member_info_response]
  content = templatefile("./templates/cs_dns_lb.tpl", {
    pub_vs_eips_list           = module.arch_bigip[*].pub_vs_eips_list[0]
    gslb_zone                  = var.app_list[count.index][1]
    gslb_zone_a_record         = var.app_list[count.index][0]
    account_id                 = local.mem_acc_id[0]
})
  filename = "${path.module}/cloud_services/f5cs4_rendered_cs_dns_lb_${count.index}.json"
}

resource "null_resource" "cs_create_dns_lb" {
  count      = length(var.app_list)
  depends_on = [local_file.rendered_cs_dns_lb]

  provisioner "local-exec" {
    command = "curl -k -X POST -H 'Content-type: application/json' -H 'Authorization: Bearer ${jsondecode(data.local_file.f5cs_login_response.content).access_token}' --data-binary '@${path.module}/cloud_services/f5cs4_rendered_cs_dns_lb_${count.index}.json' https://api.cloudservices.f5.com/v1/svc-subscription/subscriptions > ${path.module}/cloud_services/f5cs5_create_dns_lb_${count.index}.json"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "rm -f ${path.module}/cloud_services/f5cs5_create_dns_lb_${count.index}.json"
  }
}

data "local_file" "f5cs5_create_dns_lb" {
  count      = length(var.app_list)
  filename   = "${path.module}/cloud_services/f5cs5_create_dns_lb_${count.index}.json"
  depends_on = [null_resource.cs_create_dns_lb]
}

# output "z_create_info" {
#   value = jsondecode(data.local_file.f5cs5_create_dns_lb.content).subscription_id
# }

resource "null_resource" "cs_activate_dns_lb" {
  count      = length(var.app_list)
  depends_on = [local_file.rendered_cs_dns_lb]

  provisioner "local-exec" {
    command = "curl -k -X POST -H 'Content-type: application/json' -H 'Authorization: Bearer ${jsondecode(data.local_file.f5cs_login_response.content).access_token}' https://api.cloudservices.f5.com/v1/svc-subscription/subscriptions/${jsondecode(data.local_file.f5cs5_create_dns_lb[count.index].content).subscription_id}/activate > ${path.module}/cloud_services/f5cs6_activate_dns_lb_${count.index}.json"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "rm -f ${path.module}/cloud_services/f5cs6_activate_dns_lb_${count.index}.json"
  }
}