cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: private-demo-repo
  namespace: argocd
  labels:
    argocd.argoproj.io/secret-type: repository
stringData:
  url: https://github.com/billygoo/simple-web-server
  password: ${GITHUB_TOKEN}
  username: sangmo.gu@gmail.com
EOF