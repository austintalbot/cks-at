# Network policies

```bash
k create deployment frontend --image=nginx --port 80 
k create deployment  backend --image=nginx  --port 80

k expose deployment/frontend --port 80
k expose deployment/backend --port 80

# verify connectivity with no network policy

k exec deployments/frontend -- curl backend -m 1  
k exec deployments/backend -- curl frontend -m 1 

# create a default deny network policy and apply it

```

``` bash
k delete deployment frontend
k delete deployment backend

k delete svc frontend
k delete svc backend

k delete -f default-deny.yaml
k delete -f frontend-np.yaml
k delete -f backend-np.yaml

```
