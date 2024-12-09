#!/bin/bash

mkdir -p /config/cloud
cat << 'EOF' > /config/cloud/runtime-init-conf.yaml
{
    "runtime_parameters": [
        {
            "name": "HOST_NAME",
            "type": "static",
            "value": "${hostname}"
        },
        {
            "name": "ADMIN_PASS",
            "type": "static",
            "value": "${admin_pass}"
        },
        {
            "name": "EXTERNAL_IP",
            "type": "static",
            "value": "${external_ip}"
        },
        {
            "name": "INTERNAL_IP",
            "type": "static",
            "value": "${internal_ip}"
        },
        {
            "name": "INTERNAL_GW",
            "type": "static",
            "value": "${internal_gw}"
        },
        {
            "name": "MGMT_GW",
            "type": "static",
            "value": "${mgmt_gw}"
        },
        {
            "name": "VS1_IP",
            "type": "static",
            "value": "${vs1_ip}"
        },
        {
            "name": "BIGIP1",
            "type": "static",
            "value": "${bigip1}"
        },
        {
            "name": "BIGIP2",
            "type": "static",
            "value": "${bigip2}"
        },
        {
            "name": "INTERNAL_GW",
            "type": "static",
            "value": "${internal_gw}"
        },
        {
            "name": "RESOURCE_GROUP",
            "type": "static",
            "value": "${resource_group}"
        },
        {
            "name": "SUBSCRIPTION_ID",
            "type": "static",
            "value": "${subscription_id}"
        },
        {
            "name": "DIRECTORY_ID",
            "type": "static",
            "value": "${directory_id}"
        },
        {
            "name": "APPLICATION_ID",
            "type": "static",
            "value": "${application_id}"
        },
        {
            "name": "API_ACCESS_KEY",
            "type": "static",
            "value": "${api_access_key}"
        }
    ],
    "extension_packages": {
        "install_operations": [
            {
                "extensionType": "do",
                "extensionVersion": "1.15.0"
            },
            {
                "extensionType": "as3",
                "extensionVersion": "3.22.1"
            },
            {
                "extensionType": "cf",
                "extensionVersion": "1.5.0"
            },
            {
                "extensionType": "ilx",
                "extensionUrl": "https://github.com/F5Networks/f5-appsvcs-templates/releases/download/v1.3.0/f5-appsvcs-templates-1.3.0-1.noarch.rpm",
                "extensionVersion": "1.3.0",
                "extensionVerificationEndpoint": "/mgmt/shared/fast/info"
            }
        ]
    },
    "extension_services": {
        "service_operations": [
            {
                "extensionType": "do",
                "type": "inline",
                "value": ${do_declaration}
            },
            {
                "extensionType": "as3",
                "type": "inline",
                "value": ${as3_declaration}
            }
        ]
    }
}
EOF

curl https://cdn.f5.com/product/cloudsolutions/f5-bigip-runtime-init/v1.0.0/dist/f5-bigip-runtime-init-1.0.0-1.gz.run -o f5-bigip-runtime-init-1.0.0-1.gz.run && bash f5-bigip-runtime-init-1.0.0-1.gz.run -- '--cloud azure'

f5-bigip-runtime-init --config-file /config/cloud/runtime-init-conf.yaml
