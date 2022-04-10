# check status
echo "\n=== Ceph status ==="
kubectl -n rook-ceph exec deploy/rook-ceph-tools -- ceph status
echo "\n=== OSD status ==="
kubectl -n rook-ceph exec deploy/rook-ceph-tools -- ceph osd status
echo "\n=== The file system of Ceph ==="
kubectl -n rook-ceph exec deploy/rook-ceph-tools -- ceph df
echo "\n=== The file system of RADOS ==="
kubectl -n rook-ceph exec deploy/rook-ceph-tools -- rados df