
sudo groupadd --system etcd
sudo useradd -s /sbin/nologin --system -g etcd etcd
sudo chown -R etcd:etcd /var/lib/etcd/

kube-bench run --targets=master
chmod -R 600 /etc/kubernetes/pki/*.crt 
kube-bench run --targets=master  | grep fail
kube-bench run --targets=master  | grep -i fail
kube-bench run --check 1.2.5
cat /etc/kubernetes/manifests/kube-apiserver.yaml | grep ubelet-certificate-authority
cd kube-apiserver.yaml 
vi kube-apiserver.yaml 
fg
cp kube-apiserver.yaml /etc/kubernetes/manifests/ -v
c ps
watch $(c ps)
k get nodes
kube-bench run --targets=master | grep -i fail
kube-bench run --check 1.2.16
mkdir -p /var/log/apiserver/audit.log
kube-bench run --check 1.2.17
kube-bench run --check 1.2.18
kube-bench run --check 1.2.19
kube-bench run --targets=master 
