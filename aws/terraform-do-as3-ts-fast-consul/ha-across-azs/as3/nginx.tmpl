{
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
