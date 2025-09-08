# goodnotes-test

## CI Load Test

### Your Task

1. For each pull request to the default branch, trigger the CI workflow. (for example with GitHub Actions)
2. Provision a multi-node (at least 2 nodes) Kubernetes cluster (you may use KinD to provision this cluster on the CI runner (localhost))
3. Deploy Ingress controller to handle incoming HTTP requests
4. Create 2 http-echo deployments, one serving a response of “bar” and another serving a response of “foo”.
5. Configure cluster / ingress routing to send traffic for “bar” hostname to the bar deployment and “foo” hostname to the foo deployment on local cluster (i.e. route both http://foo.localhost and http://bar.localhost).
6. Ensure the ingress and deployments are healthy before proceeding to the next step.
7. Generate a load of randomized traffic for bar and foo hosts and capture the load testing result
8. Post the output of the load testing result as comment on the GitHub Pull Request (automated the CI job). Depending on the report your load testing script generates, ideally you'd post stats for http request duration (avg, p90, p95, ...), % of http request failed, req/s handled.

### Getting Started

Please review the information in this section before you get started with your development.

- Create a GitHub repository to implement the above tasks.
- When you are ready, download the repo as a Zip and upload it to the link at the bottom of this email, ideally with a sample PR which executed the CI workflow and has a comment with the result in it.

### Tech Stack

You may choose to develop the application using either of the following stack:

- GitHub Actions to implement the workflow (or a CI of your choice, as long as we can review the CI logs).
- Bash/Golang/Typescript/Python/HCL or a combination of these to orchestrate the steps in the workflow

### Basic Expectation

- Ability to write clear documentation on the implementation
- Write readable, maintainable, performant and reliable code.
- Validate progress within the script evaluating workload status
- Account for failures and consider handling them gracefully
- Write clear and concise commit message.

## Challenge Yourself

Additional consideration to fine-tune your solution. It's not a must to implement in this assignment but please be prepared to discuss:

- Avoid boilerplate and repetition of configuration.
- Declarative over Imperative.
- Use the best tool for the job, research and consider the right tools and be able to explain choices made.
- Stretch goal: deploy a monitoring solution (prometheus?) for the workload, capture resource utilisation to augment the load testing report.

## Time Estimates

This assignment should take about 3 to 5 hours of your time depending on your level of experience. Please monitor and report the time taken in your readme. Important: We understand that the take-home test will take up some of your personnal time. If you need more time to complete it, please let us know how much time you will need by replying to this email.

## Pitfalls to avoid

Chinese network environment is quite different from other places, so please avoid using some tools or images that are not accessible in china, for example, kindest/node image, or some actions in github actions marketplace.

- For kind create cluster: Set HTTP_PROXY, HTTPS_PROXY, and NO_PROXY environment variables. The kind process will automatically pass these to the cluster nodes. host.docker.internal is the correct value to use for macOS.
- For kubectl apply: Unset the proxy environment variables. This allows kubectl on your host machine to communicate directly with the local cluster's API server without attempting to go through a proxy.

## Local Test Steps

1. Set the proxy environment variables

```shell
export HTTP_PROXY=http://host.docker.internal:7890
export HTTPS_PROXY=http://host.docker.internal:7890
export NO_PROXY=localhost,127.0.0.1,.svc,.cluster.local,10.96.0.0/12
```

2. setup the cluster

`source scripts/setup-cluster.sh`

3. switch vpn

```shell
export HTTP_PROXY=http://127.0.0.1:7890
export HTTPS_PROXY=http://127.0.0.1:7890
export NO_PROXY=localhost,127.0.0.1,.svc,.cluster.local,10.96.0.0/12
```

4. deploy echo services and ingress

`kubectl apply -f k8s/k8s-manifest.yaml`
`kubectl patch service ingress-nginx-controller -n ingress-nginx -p '{"spec":{"type":"NodePort","ports":[{"name":"http","nodePort":30080,"port":80,"protocol":"TCP","targetPort":"http"},{"name":"https","nodePort":30443,"port":443,"protocol":"TCP","targetPort":"https"}]}}'`
check the ingress pod is ready:
`kubectl wait --namespace ingress-nginx   --for=condition=ready pod   --selector=app.kubernetes.io/component=controller   --timeout=300s`

5. local test

```shell
curl -H "Host: foo.localhost" http://localhost
curl -H "Host: bar.localhost" http://localhost
```

## pre-requisites

- docker: brew install docker-desktop
- kubectl: brew install kubectl
- kind: brew install kind
- nginx ingress controller: brew install ingress-nginx
