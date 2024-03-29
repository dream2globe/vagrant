# 내 PC에 Kubernetes 쉽게 설치하기
Virtual Box와 Vagrant를 사용하여 Kubernetes Cluster를 쉽게 구성하는 방법입니다. 

## 환경
* OS: Ubuntu 22.04
* HW: Intel 10700K, 32GB Memory. 1TB SSD

저와 OS 환경과 다르더라도 Windows, Mac에서도 실행이 가능할 것 같습니다. 혹시 시도해보신 분 계시면 저에게도 알려주시면 감사하겠습니다.

## 설치 순서

### K8S Cluster
Virutal Box와 Vagrant의 사전 설치가 필요합니다. 아래 글과 공식 홈페이지를 참조하여 본인에 맞는 release를 설치합니다.
* [Virutal Box](https://www.virtualbox.org/wiki/Linux_Downloads)
  * 참고로 홈페이지를 통해 설치할 경우 7.0 버전이 설치되나 아래 apt 명령어를 사용하면 6.1 버전이 설치됩니다. 다만 k8s에는 어느 버전을 설치해도 잘 동작합니다. 

```bash
$ sudo apt install virtualbox
```
* [Vagrant](https://www.vagrantup.com/downloads/) 

```bash
$ wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
$ echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
$ sudo apt update && sudo apt install vagrant
```

다음 프로젝트를 구성할 폴더를 생성하고 VM 설정이 담긴 파일들을 복사합니다. 이후 생성된 폴더로 이동하여 `vagrant up` 명령어를 실행합니다. 모든 작업은 끝났습니다. 1개의 master node와 3개의 worker node로 구성된 cluster가 생성될 때까지 기다리면 됩니다.

```bash
$ git clone https://github.com/dream2globe/vagrant.git
$ cd vagrant
$ export VAGRANT_EXPERIMENTAL="disks"  # 디스크 추가를 위한 실험기능 활성화(ceph 설치 시 필요)
$ vagrant up
$ vagrant ssh kmaster  # 가상머신 master ssh 접속
$ k get nodes  # cluster node 확인
```

## VM 설정 방법
PC 사양 및 환경을 고려하여 VM을 조절해아할 수 있습니다. 아래에는 각 설정 파일의 주요 항목을 설명하였습니다.

### Vagrantfile
docker의 dockerfile과 유사한 역할로 VM의 Base OS, 사용 자원 등을 설정합니다. 
* num_node = 3
  * 설치될 worker node의 수로, master를 포함하여 총 4개의 node가 설치됨
* config.vm.box = "ubuntu/jammy64"
  * Ubuntu 22.04를 VM의 OS로 설치
* vb.memory = "4096" / vb.cpus = "3"
  * VM에 할당될 메모리와 CPU core 수
  * 4개의 VM이 설치되므로, 총 16GB/12core가 할당됨
  * K8S는 노드당 최소 2core, 2GB(ceph 추가 시 최소 4GB 권장)가 필요하므로 최소 노드로 설정했음에도 용량이 부족한 경우에는 worker 수 조절 필요
* config.vm.provision :shell, privileged: true,  path: "vagrant_k8s_common.sh"
  * 필요한 패키지 및 환경 설정을 위한 shell 명령어
  * privileged(boolean): sudo 권한 유무
* main.vm.network "private_network", ip: "192.168.56.21"
  * guest에서만 접근 가능한 network 구성
  * 고정 IP로 설정함

### vagrant_k8s_common.sh
모든 노드에 동일하게 설치되는 패키지 및 환경 설정 방법이 담겨 있습니다. 

### vagrant_k8s_main.sh
master 노드에만 추가 반영이 필요한 설정이 담겨 있습니다.

## Vagrant 명령어
Vagrant는 VM 전체를 단순한 명령어로 쉽게 제어할 수 있습니다.
* `vagrant up`: Vagrantfile을 참조하여 VM을 기동합니다 
* `vagrant halt`: 모든 VM 정지
* `vagrant destroy`: 모든 VM 제거
* `vagrant box list`: 설치되어 있는 Box(Container의 Image와 유사 개념)

이외 명령어는 [Vagrant Tutorial](https://learn.hashicorp.com/collections/vagrant/getting-started)에 친절하게 소개하고 있으니 꼭 참고해보시길 추천합니다.

## Tips
### Vagrant client 없이 ssh로 접속하기
아래의 방법으로 vagrant가 자동으로 설정한 인증키를 복사한 후 ssh에 적용할 수 있습니다. 

```bash
$ vagrant ssh-config > vagrant-ssh
$ ssh -F vagrant-ssh vagrant@kmaster 
```

이러한 방법을 응용하면 scp를 사용하여 kmaster VM의 `~/.kube` 폴더를 호스트 영역으로 복사할 수 있으며,
복사 이후에는 kmaster VM 내부에 접속하지 않더라도 호스트 영역에서 직접 kubectl로 명령을 내려 k8s 클러스터를 제어할 수 있습니다. 
※ 호스트에 kubectl 설치 방법은 [여기 링크](https://kubernetes.io/ko/docs/tasks/tools/install-kubectl-linux/)를 참고하세요.

```bash
$ scp -r -F vagrant-ssh vagrant@kmaster:/home/vagrant/.kube /home/shyeon/
❯ kubectl get nodes
NAME       STATUS   ROLES           AGE    VERSION
kmaster    Ready    control-plane   7h6m   v1.28.2
kworker1   Ready    <none>          7h5m   v1.28.2
kworker2   Ready    <none>          7h3m   v1.28.2
kworker3   Ready    <none>          7h1m   v1.28.2
```
### VM간 파일 공유하기
`Vagrantfile` 파일이 있는 Host PC의 폴더와 VM 내부의 `/Vagrant` 폴더는 자동으로 마운드 됩니다. 따라서 `/Vagrant` 내부의 모든 파일은 `vagrant up`으로 동시에 생성된 VM의 `/Vagrant`에서 모두 접근 가능합니다. 본 튜토리얼에서도 이러한 특성을 활용하여 kmaster에서 생성한 `/Vagrant/k8s_join.sh`를 모든 kworker에서 실행하여 클러스터에 등록하는 것을 확인할 수 있습니다. 

## Release
* (2022.04.10) MetalLB 설정 방법을 추가했습니다.
* (2022.05.05) ubuntu 22.04에서 vargrant 사용 시 문제 해결 방법을 추가했습니다. 
               k8s version upgrade에 따른 컨테이너 런타임 미인식 문제를 수정했습니다. 
* (2022.10.22) Tips 설명을 추가했습니다. 
* (2023.10.02) k8s version 1.28.2를 감안하여 설치 명령어를 수정했습니다. 
