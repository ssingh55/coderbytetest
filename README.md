# coderbytetest

## configure aws cli
export AWS_ACCESS_KEY_ID=""
export AWS_SECRET_ACCESS_KEY=""

## kubectl
aws eks list-clusters --region us-east-1
aws eks update-kubeconfig --region us-east-1 --name k8s-cluster
kubectl config get-contexts
kubectl config use-context arn:aws:eks:us-east-1:081006037460:cluster/k8s-cluster
kubectl get nodes

## setup jenkins
apt-get install openjdk-11-jdk -y
sudo wget -O /usr/share/keyrings/jenkins-keyring.asc \
  https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc]" \
  https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null
sudo apt-get update
sudo apt-get install jenkins
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
wget https://get.jenkins.io/debian-stable/jenkins_2.426.1_all.deb
sudo usermod -aG docker jenkins

## Deploy ingress controller nginx
### create the ingress namespace
kubectl create namespace ingress-nginx

### deploy nginx using the official manifest
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/cloud/deploy.yaml

### verify the deployments
kubectl get pods -n ingress-nginx
kubectl get svc -n ingress-nginx

### deploy the nodejs application
kubectl apply -f nodejs-app.yaml

### create the ingress resource
kubectl apply -f nodejs-ingress.yaml