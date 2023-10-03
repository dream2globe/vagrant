kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.7/config/manifests/metallb-native.yaml
kubectl create -f ip_address_pool.yaml
kubectl create -f l2_advertisement.yaml
