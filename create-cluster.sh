docker-machine create --driver virtualbox master1
docker-machine create --driver virtualbox worker1
docker-machine create --driver virtualbox worker2

echo "Initializing the swarm mode"
master_ip=$(docker-machine ip master1)
docker-machine ssh master1 docker swarm init --advertise-addr $master_ip

worker_tkn=$(docker-machine ssh master1 docker swarm join-token -q worker)
echo "Worker token: ${worker_tkn}"

docker-machine ssh worker1 docker swarm join --token $worker_tkn $master_ip:2377
docker-machine ssh worker2 docker swarm join --token $worker_tkn $master_ip:2377

docker-machine ssh master1 docker network create monitoring -d overlay
docker-machine ssh master1 docker service create --network=monitoring \
  --mount type=volume,target=/usr/share/elasticsearch/data \
  --constraint node.hostname==worker1 \
  --name elasticsearch elasticsearch:2.4.0
docker-machine ssh master1 docker service create --network=monitoring --name kibana -e ELASTICSEARCH_URL="http://elasticsearch:9200" -p 5601:5601 kibana:4.6.0

