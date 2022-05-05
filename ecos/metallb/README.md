# MetalLB Configuration
MetalLB는 LoadBalance로 노출하려는 service에 ip를 자동으로 할당합니다. 본 문서는 MetalLB의 "Layer 2 Configuration" 방법을 활용하여 할당 가능한 ip 대역을 설정하는 방법을 설명합니다. 설치방법 등 자세한 내용은 [MetalLB 홈페이지](https://metallb.universe.tf/)를 참조하세요. 사용한 버전은 (MetalLB v0.12.1) 입니다.

* [Network-확인](#network-확인)
* [Configmap으로-ip대역-설정](#configmap으로-ip대역-설정)

## Network 확인
명령어 `ip a s`를 입력하여 VirtualBox가 사용하는 network bridge를 확인합니다.

```
$ ip a s

1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host 
       valid_lft forever preferred_lft forever
2: enp3s0: <NO-CARRIER,BROADCAST,MULTICAST,UP> mtu 1500 qdisc fq_codel state DOWN group default qlen 1000
    link/ether a8:a1:59:26:6c:ee brd ff:ff:ff:ff:ff:ff
3: eno1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether a8:a1:59:26:52:1c brd ff:ff:ff:ff:ff:ff
    altname enp0s31f6
    inet 192.168.25.34/26 brd 192.168.25.63 scope global dynamic noprefixroute eno1
       valid_lft 1935sec preferred_lft 1935sec
    inet6 fe80::eaa9:51f4:a518:750c/64 scope link noprefixroute 
       valid_lft forever preferred_lft forever
4: wlp2s0: <NO-CARRIER,BROADCAST,MULTICAST,UP> mtu 1500 qdisc noqueue state DOWN group default qlen 1000
    link/ether 54:8d:5a:cd:be:9b brd ff:ff:ff:ff:ff:ff
5: docker0: <NO-CARRIER,BROADCAST,MULTICAST,UP> mtu 1500 qdisc noqueue state DOWN group default 
    link/ether 02:42:51:51:b5:27 brd ff:ff:ff:ff:ff:ff
    inet 172.17.0.1/16 brd 172.17.255.255 scope global docker0
       valid_lft forever preferred_lft forever
6: vboxnet0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 0a:00:27:00:00:00 brd ff:ff:ff:ff:ff:ff
    inet 192.168.56.1/24 brd 192.168.56.255 scope global vboxnet0
       valid_lft forever preferred_lft forever
    inet6 fe80::800:27ff:fe00:0/64 scope link 
       valid_lft forever preferred_lft forever
```

위 경우에는 vboxnet0을 사용하고 있고 ip 대역이 192.168.56.1/24 임을 알 수 있습니다. 명령어 `sipcalc 192.168.56.1/24`를 입력하여 사용 가능한 ip를 확인합니다.

```bash
$ sipcalc 192.168.56.1/24

[CIDR]
Host address		- 192.168.56.1
Host address (decimal)	- 3232249857
Host address (hex)	- C0A83801
Network address		- 192.168.56.0
Network mask		- 255.255.255.0
Network mask (bits)	- 24
Network mask (hex)	- FFFFFF00
Broadcast address	- 192.168.56.255
Cisco wildcard		- 0.0.0.255
Addresses in network	- 256
Network range		- 192.168.56.0 - 192.168.56.255
Usable range		- 192.168.56.1 - 192.168.56.254
```

## Configmap으로 ip대역 설정
아래는 사용 가능한 ip 대역 중 끝부분의 20개 ip를 자동 할당하도록 설정한 예시입니다. 

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  namespace: metallb-system
  name: config
data:
  config: |
    address-pools:
    - name: default
      protocol: layer2
      addresses:
      - 192.168.56.230-192.168.56.250
```

위 설정을 저장하고 configmap을 생성하여 모든 과정을 완료합니다.

```bash
$ cat << EOF >> configmap_to_set_service_ip_range.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  namespace: metallb-system
  name: config
data:
  config: |
    address-pools:
    - name: default
      protocol: layer2
      addresses:
      - 192.168.56.230-192.168.56.250
EOF

$ kubectl create -f configmap_to_set_service_ip_range.yaml
```
