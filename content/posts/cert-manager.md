+++
author = "Luis Michael Ibarra"
title = "Cert Manager Notes"
date = "2020-03-07"
tags = [
    "kubernetes",
    "security",
    "cert-manager",
]
draft = true
+++

As cert-manager approaches to hit v1.0 I found a few things that I need to start 
tracking like versioning, secrets, and other peculiarities about its functionality on kubernetes.

## How it works

Cert manager has different components: an issuer, a certificate request, a certificate, an ACME order and challenge.

You define an issuer with some information like ACME server, email, a private key which 
is your secret to communicate with the ACME server, and a set of solvers.

After deploying your issuer, you need to add an annotation and a tls section to you application ingress, so 
the cert-manager webhook can start creating a certificate request to get a certificate.
The TLS section *must have a different secret name than you issuer secret name*.
As the certificate request is submitted it will create an order which generates a challenge 
to the server. After the challenge validates the domain and ipaddress, the certificate is 
generated.
