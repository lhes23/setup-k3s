# Install k3s in Ubuntu 2204 - AMD64

## Copy `setup-k3s`
Run setup-k3s

## Install ArgoCD
```
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

## Install Nginx using helm
```
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace
```

## to download docker image from Artifact Registry
```
gcloud auth configure-docker
```

## Print token
```
gcloud auth print-access-token
```

## Create a `registries.yaml`
```
sudo vim /etc/rancher/k3s/registries.yaml
```

```
mirrors:
  asia-southeast1-docker.pkg.dev:
    endpoint:
      - "https://asia-southeast1-docker.pkg.dev"

configs:
  asia-southeast1-docker.pkg.dev:
    auth:
      username: oauth2accesstoken
      password: "<YOUR_ACCESS_TOKEN_FROM_STEP_1>"

```
## Restart K3S
```
sudo systemctl restart k3s
```


## Install Cert Manager
```
helm repo add jetstack https://charts.jetstack.io
helm repo update
```
```
kubectl apply --validate=false -f https://github.com/cert-manager/cert-manager/releases/latest/download/cert-manager.crds.yaml
```
```
helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version v1.15.0
```

## Create ClusterIssuer
```
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: your-email@example.com
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: nginx
```
```
kubectl apply -f clusterissuer.yaml
```

> Add this to the ingress
> 
```
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: example-ingress
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
spec:
  tls:
  - hosts:
    - example.com
    secretName: example-com-tls
```
