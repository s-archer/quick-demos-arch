#!/bin/bash

mkdir -p /config/cloud
cat << 'EOF' > /config/cloud/runtime-init-conf.yaml
{
    "controls": {
        "extensionInstallDelayInMs" : 10000,
        "logLevel": "silly"
    },
    "runtime_parameters": [],
    "pre_onboard_enabled": [
        {
            "name": "create_LOCAL_ONLY_partition_and_route",
            "type": "inline",
            "commands": [
                "tmsh create net vlan internal { interfaces add { 1.2 } tag 1002 }",
                "tmsh create net self internal-self { address ${internal_ip_raw} allow-service default traffic-group traffic-group-local-only vlan internal }",
                "tmsh create sys folder /LOCAL_ONLY device-group none traffic-group traffic-group-local-only",
                "tmsh -q -c 'cd /LOCAL_ONLY; create net route default { gw ${internal_gw_raw} network default }'",
                "tmsh save sys config partitions all",
                "sleep 10"
            ]
        }
    ],
    "extension_packages": {
        "install_operations": [
            {
                "extensionType": "do",
                "extensionVersion": "1.46.0"
            },
            {
                "extensionType": "as3",
                "extensionVersion": "3.53.0"
            },
            {
                "extensionType": "cf",
                "extensionVersion": "1.9.0"
            },
            {
                "extensionType": "fast",
                "extensionVersion": "1.10.0"
            }
        ]
    },
    "extension_services": {
        "service_operations": [
            {
                "extensionType": "do",
                "type": "inline",
                "value":               {
                    "schemaVersion": "1.0.0",
                    "class": "Device",
                    "async": true,  
                    "label": "my BIG-IP declaration for declarative onboarding",
                    "Common": {
                        "class": "Tenant",
                        "hostname": ${hostname},
                        "admin": {
                            "class": "User",
                            "userType": "regular",
                            "password": ${admin_pass},
                            "shell": "bash"
                        },
                        "dbvars": {
                            "class": "DbVariables",
                            "provision.extramb": 2048
                        },
                        "myProvisioning": {
                            "class": "Provision",
                            "ltm": "nominal"
                        },
                        "myDns": {
                            "class": "DNS",
                            "nameServers": [
                            ${dns}
                            ],
                            "search": [
                                "f5.com",
                                "test.com"
                            ]
                        },
                        "myNtp": {
                            "class": "NTP",
                            "servers": [
                                ${ntp}
                            ],
                            "timezone": "UTC"
                        },
                        "external": {
                            "class": "VLAN",
                            "tag": 1001,
                            "mtu": 1500,
                            "interfaces": [
                                {
                                    "name": "1.1",
                                    "tagged": false
                                }
                            ]
                        },
                        "external-self": {
                            "class": "SelfIp",
                            "address": ${external_ip},
                            "vlan": "external",
                            "allowService": "none",
                            "trafficGroup": "traffic-group-local-only"
                        },
                        "internal": {
                            "class": "VLAN",
                            "tag": 1002,
                            "mtu": 1500,
                            "interfaces": [
                                {
                                    "name": "1.2",
                                    "tagged": false
                                }
                            ]
                        },
                        "internal-self": {
                            "class": "SelfIp",
                            "address": ${internal_ip},
                            "vlan": "internal",
                            "allowService": "default",
                            "trafficGroup": "traffic-group-local-only"
                        },
                        "configsync": {
                            "class": "ConfigSync",
                            "configsyncIp": "/Common/internal-self/address"
                        },
                        "failoverAddress": {
                            "class": "FailoverUnicast",
                            "address": "/Common/internal-self/address"
                        },
                        "failoverGroup": {
                            "class": "DeviceGroup",
                            "type": "sync-failover",
                            "members": [${bigip1}, ${bigip2}],
                            "owner": ${bigip1},
                            "autoSync": true,
                            "saveOnAutoSync": false,
                            "networkFailover": true,
                            "fullLoadOnSync": false,
                            "asmSync": false
                        },
                        "trust": {
                            "class": "DeviceTrust",
                            "localUsername": "admin",
                            "localPassword": ${admin_pass},
                            "remoteHost": ${bigip1},
                            "remoteUsername": "admin",
                            "remotePassword": ${admin_pass}
                        }
                    }
                }
            },
            {
                "extensionType": "as3",
                "type": "inline",
                "value": {
                    "class": "AS3",
                    "action": "deploy",
                    "persist": true,
                    "syncToGroup": "/Common/failoverGroup",
                    "declaration": {
                        "class": "ADC",
                        "schemaVersion": "3.7.0",
                        "id": "Consul_SD",
                        ${tenant_name}: {
                            "class": "Tenant",
                            ${app_name}: {
                                "class": "Application",
                                "template": "http",
                                "serviceMain": {
                                    "class": "Service_HTTP",
                                    "virtualPort": 80,
                                    "virtualAddresses": [
                                        {
                                            "use": "serviceAddress1"
                                        },
                                        {
                                            "use": "serviceAddress2"
                                        }            
                                    ],
                                    "pool": "web_pool",
                                    "persistenceMethods": [],
                                    "profileMultiplex": {
                                        "bigip": "/Common/oneconnect"
                                    }
                                },
                                "serviceAddress1":{
                                    "class":"Service_Address",
                                    "virtualAddress": ${virtual_ip_1},
                                    "trafficGroup":"none"
                                },
                                "serviceAddress2":{
                                    "class":"Service_Address",
                                    "virtualAddress": ${virtual_ip_2},
                                    "trafficGroup":"none"
                                },
                                "web_pool": {
                                    "class": "Pool",
                                    "monitors": [
                                        "http"
                                    ],
                                    "members": [
                                        {
                                            "servicePort": 80,
                                            "addressDiscovery": "consul",
                                            "updateInterval": 10,
                                            "uri": "http://10.0.2.100:8500/v1/catalog/service/nginx",
                                            "jmesPathQuery":"[*].{id:ID||Node,ip:{private:Address,public:Address},port:ServicePort}",
                                            "credentialUpdate": false
                                        }
                                    ]
                                }
                            }
                        }
                    }
                }
            },
            {
                "extensionType": "cf",
                "type": "inline",
                "value":                 {
                    "class": "Cloud_Failover",
                    "environment": "aws",
                    "externalStorage": {
                        "scopingTags": {
                            "f5_cloud_failover_label": "mydeployment"
                        }
                    },
                    "failoverAddresses": {
                        "enabled": true,
                        "scopingTags": {
                            "f5_cloud_failover_label": "mydeployment"
                        }
                    },
                    "controls": {
                        "class": "Controls",
                        "logLevel": "silly"
                    }
                }
            }            
        ]
    }
}
EOF

# curl https://cdn.f5.com/product/cloudsolutions/f5-bigip-runtime-init/v1.2.1/dist/f5-bigip-runtime-init-1.2.1-1.gz.run -o f5-bigip-runtime-init-1.2.1-1.gz.run && bash f5-bigip-runtime-init-1.2.1-1.gz.run -- '--cloud aws'

# f5-bigip-runtime-init --config-file /config/cloud/runtime-init-conf.yaml

# Download
for i in {1..30}; do
    # curl -fv --retry 1 --connect-timeout 5 -L "https://cdn.f5.com/product/cloudsolutions/f5-bigip-runtime-init/v2.0.1/dist/f5-bigip-runtime-init-2.0.1-1.gz.run" -o "/var/config/rest/downloads/f5-bigip-runtime-init.gz.run" && break || sleep 10
    curl -fv --retry 1 --connect-timeout 5 -L "https://cdn.f5.com/product/cloudsolutions/f5-bigip-runtime-init/v2.0.3/dist/f5-bigip-runtime-init-2.0.3-1.gz.run" -o "/var/config/rest/downloads/f5-bigip-runtime-init.gz.run" && break || sleep 10
done
# Install
bash /var/config/rest/downloads/f5-bigip-runtime-init.gz.run -- "--cloud aws"
# Run
f5-bigip-runtime-init --config-file /config/cloud/runtime-init-conf.yaml