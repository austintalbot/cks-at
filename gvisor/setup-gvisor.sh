#!/bin/bash

docker cp gvisor-install.sh test-control-plane:/root/    
docker exec -it test-control-plane /bin/bash -c  /root/gvisor-install.sh

docker cp gvisor-install.sh test-worker:/root/
docker exec -it test-worker /bin/bash -c  /root/gvisor-install.sh

docker cp gvisor-install.sh test-worker2:/root/
docker exec -it test-worker2 /bin/bash -c  /root/gvisor-install.sh