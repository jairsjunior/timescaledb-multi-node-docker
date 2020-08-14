# Timescale DB Cluster using Docker

At version 2 (in beta, no production recommended), timescale will had a new functionality that distribute hypertables over different data nodes chunks. This repository contains all you need to setup this using docker locally at your machine.

![Architecture](https://user-images.githubusercontent.com/31451796/90265828-82efcb00-de29-11ea-81cf-4c42a9634eaa.png)

## Requirements

- Docker
- docker-compose

## Getting Started

### Starting the cluster

1. Clone this repo to your machine
```
git clone https://github.com/jairsjunior/timescaledb-cluster
```
2. Run the docker-compose file using this command
```
docker-compose up -d
```
3. The access node will be avaliable at this address `localhost:5432`

### Create your first distributed hypertable

Using your favorite timescale/postgres client

1. Check if your data nodes are registered using the command below. If everything is okay you will receive a response with the number of data nodes that you created. (default docker-compose.yml file creates 3 nodes)
```
SELECT * FROM timescaledb_information.data_node;
```
2. Create a new table
```
CREATE TABLE state (time TIMESTAMPTZ NOT NULL, owner CHARACTER VARYING(100) NOT NULL, thing CHARACTER VARYING(100) NOT NULL, node CHARACTER VARYING(100) NOT NULL, tags JSONB, fields JSONB, CONSTRAINT state_pk PRIMARY KEY (time, owner, thing, node));
```
3. Setup this table as a distributed hypertable (partitioned along time and owner)
```
SELECT create_distributed_hypertable('state', 'time', 'owner');
```
4. If everything goes right, you know have a distributed hypertable over your data nodes.

### Adding new nodes to our cluster

1. At `docker-compose.yml` file add this lines below
```
    pg-data-node-4:
        image: timescaledev/timescaledb:pg12-ts2.0.0-beta5
        hostname: pg-data-node-4
        environment:
        - POSTGRES_PASSWORD=coffee
        - POSTGRES_HOST_ACCESS_NODE=pg-access-node
        - POSTGRES_PASSWORD_ACCESS_NODE=tea
        volumes:
        - ./updateConfigDataNode.sh:/docker-entrypoint-initdb.d/_updateConfig.sh
        - ./docker-entrypoint-listen.sh:/docker-entrypoint.sh
```
2. Run the docker-compose up command to create/update your existing containers.
```
docker-compose up -d
```
3. When the data node starts, it register yourself as a new data node in the cluster.
4. In a few second the new node are ready to receive data.

### Adding new nodes to your distributed hypertable

- Using your favorite timescale/postgres client

1. Run the command below to add a new node to your distributed hypertable passing the new node hostname as `NEW_NODE_HOSTNAME` and the hypertable name as `HYPERTABLE_NAME`
```
SELECT attach_data_node('${NEW_NODE_HOSTNAME}', hypertable => '${HYPERTABLE_NAME}');
```
Eg.
```
SELECT attach_data_node('pg-data-node-4', hypertable => 'state');
```
