+++
author = "Luis Michael Ibarra"
title = "Playing with the Kubernetes API"
date = "2020-05-15"
tags = [
    "kubernetes",
    "api",
    "kubcetl",
    "watch",
]
+++

In my journey to learn the Kubernetes API, the first part is to connect to it. 

You could use simple `curl` using credentials from `$KUBECONFIG` to do it, but 
Kubernetes provides a simpler and better way to connect to it: `kubectl proxy --port=8080`.
This command will create a proxy between your localhost and your target kubernetes API 
according to your current kubernetes context.

After that you could keep using curl to just communicate to the api like 
`curl localhost:8080/apis/apps/v1/deployments`; however, you can replicate the 
same with `kubectl` using `kubectl get --raw=<uri>`. For instance, the previous 
curl command can be translated to `kubectl get --raw=/apis/apps/v1/deployments`.

## Watch - Checking Kubernetes events in a resource

If you are curious about which events are happening in a resource, you can use 
watch for it. For this, you need the Kubernetes object resource version which 
can be used to initiate a watch against the server. The server will return all 
changes(creates, deletes and updates) that occur after the supplied `resourceVersion`.

    #Starting proxy
    $kubectl proxy --port=8080

    #Obtaining resourceVersion
    $RESOURCE_VERSION=$(kubectl get --raw=/api/v1/namespaces/default/pods | jq -r .metadata.resourceVersion)

    #Starting watch
    $kubectl get --raw=/api/v1/namespaces/default/pods?watch=1&resourceVersion=${RESOURCE_VERSION}
 
The watch in Linux starts as a background job by default. You can check it with 
`jobs`. After that, you can bring it to the foreground using `fg [job_number]`.
If the client disconnects, you can restart it using the last returned `resourceVersion`, 
or performing a new request and begin again.


## Bibliography

- https://kubernetes.io/docs/reference/using-api/api-concepts/#efficient-detection-of-changes
