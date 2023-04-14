# simple-argocd
argocd 설정 저장소


# Installation 
Argocd의 경우 테스트 프로젝트 이기 때문에 특별한 설정하지 않고 다음 명령을 통해 빠르게 설치합니다. 

```bash
# argocd 
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# argocd notification & triggers (위에 초기 설치 버전에 다 추가되어 있음)
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj-labs/argocd-notifications/release-1.0/manifests/install.yaml

kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj-labs/argocd-notifications/release-1.0/catalog/install.yaml


# argocd rollout
kubectl create namespace argo-rollouts
kubectl apply -n argo-rollouts -f https://github.com/argoproj/argo-rollouts/releases/latest/download/install.yaml


# argocd CLI 설치 
mkdir -p ~/.local/bin
export PATH=${HOME}/.local/bin:$PATH
curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
sudo install -m 555 argocd-linux-amd64 ~/.local/bin/argocd
rm argocd-linux-amd64
```


# Argocd 사용하기 
다음 명령을 따라해서 초기 암호 및 접속 주소를 활성화 한다. public endpoint 노출을 최소화하기 위해 `port-forward` 명령을 활용해 로컬에서 접속 할 수 있도록 한다. 

```bash
# 초기 암호 읽어오기 
$ kubectl get -n argocd secret argocd-initial-admin-secret --template={{.data.password}} | base64 -d
decoded_password  # 암호 복사  

$ kubectl get svc -n argocd
NAME                                      TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)                      AGE
argocd-applicationset-controller          ClusterIP   172.20.23.121    <none>        7000/TCP,8080/TCP            21m
argocd-dex-server                         ClusterIP   172.20.59.175    <none>        5556/TCP,5557/TCP,5558/TCP   21m
argocd-metrics                            ClusterIP   172.20.137.109   <none>        8082/TCP                     21m
argocd-notifications-controller-metrics   ClusterIP   172.20.72.117    <none>        9001/TCP                     21m
argocd-redis                              ClusterIP   172.20.64.7      <none>        6379/TCP                     21m
argocd-repo-server                        ClusterIP   172.20.115.113   <none>        8081/TCP,8084/TCP            21m
argocd-server                             ClusterIP   172.20.191.141   <none>        80/TCP,443/TCP               21m
argocd-server-metrics                     ClusterIP   172.20.72.201    <none>        8083/TCP                     21m

$ kubectl port-forward svc/argocd-server 9090:443
Forwarding from 127.0.0.1:9090 -> 8080
Forwarding from [::1]:9090 -> 8080
Handling connection for 9090
Handling connection for 9090
Handling connection for 9090
...
```

## argocd cli로 연결하기 
```bash
$ argocd login 127.0.0.1:9090
WARNING: server certificate had error: x509: cannot validate certificate for 127.0.0.1 because it doesn't contain any IP SANs. Proceed insecurely (y/n)? y
Username: admin
Password:
'admin:login' logged in successfully
Context '127.0.0.1:8080' updated
```

## 웹 브라우저로 연결하기 
브라우저에서 `https://127.0.0.1:9090`에 접속해 다음 암호를 이용해 로그인 한다. 
- ID : `admin`
- Password : 앞 단계에 확인한 초기 암호값


## Cluster 등록하기 
Argocd cli를 활용하면 현재 보유하고 있는 kubernetes config file(`~/.kube/config`) 정보를 이용해 클러스터를 등록할 수 있다. 
```bash
$ kubectl config get-contexts -o name
cicd-eks
staging-eks

$ argocd cluster add staging-eks
WARNING: This will create a service account `argocd-manager` on the cluster referenced by context `staging-eks` with full cluster level privileges. Do you want to continue [y/N]? y
INFO[0005] ServiceAccount "argocd-manager" created in namespace "kube-system"
INFO[0005] ClusterRole "argocd-manager-role" created
INFO[0005] ClusterRoleBinding "argocd-manager-role-binding" created
INFO[0011] Created bearer token secret for ServiceAccount "argocd-manager"
Cluster 'https://xzxxxxxxxxxxxxxxxxxxxxxx.gr7.ap-northeast-2.eks.amazonaws.com' added

$ argocd cluster add cicd-eks
WARNING: This will create a service account `argocd-manager` on the cluster referenced by context `cicd-eks` with full cluster level privileges. Do you want to continue [y/N]? y
INFO[0001] ServiceAccount "argocd-manager" created in namespace "kube-system"
INFO[0001] ClusterRole "argocd-manager-role" created
INFO[0001] ClusterRoleBinding "argocd-manager-role-binding" created
INFO[0006] Created bearer token secret for ServiceAccount "argocd-manager"
Cluster 'https://yyyyyyyyyyyyyyyyyyyyyyyy.yl4.ap-northeast-2.eks.amazonaws.com' added
```

## Slack Token 배포하기 
```bash
# Slack Token 등록하기
export SLACK_TOKEN=<your-slack-token>
kubectl apply -n argocd -f - << EOF
apiVersion: v1
kind: Secret
metadata:
  name: argocd-notifications-secret
stringData:
  slack-token: $SLACK_TOKEN
EOF

# slack 알림 등록하기
kubectl patch cm argocd-notifications-cm -n argocd --type merge -p '{"data": {"service.slack": "{ token: $slack-token }" }}'
```

# Application 배포하기 
1. [application/staging/simple-web-server](application/staging/simple-web-server) 을 배포하기 위해서는 다음 두 가지 작업을 한다. 
  1. application.yaml 은 `kubectl`을 이용해 배포한다. 
  2. secret.sh 의 경우는 다음과 같이 환경변수를 이용해 배포 한다. 
  ```bash
  export GITHUB_TOKEN=xxxxxx
  source secret.sh
  ```

# 고려사항 
다음은 추후 운영 관리를 위해서 추가로 개선할 필요가 있는 항목들을 정리했다. 

1. ArgoCD 계정 관리 연동을 이용한 권한 관리 추가
2. rollout 배포시 자동으로 세팅 되도록 하는 방법 확인 


