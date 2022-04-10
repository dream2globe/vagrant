# deploy cluster
kubectl create -f /vagrant/ecos/rook/deploy/examples/crds.yaml
kubectl create -f /vagrant/ecos/rook/deploy/examples/common.yaml
kubectl create -f /vagrant/ecos/rook/deploy/examples/operator.yaml
kubectl create -f /vagrant/ecos/rook/deploy/examples/cluster.yaml
kubectl create -f deploy/examples/toolbox.yaml  # toolbox