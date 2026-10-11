# Addressing Plan

## Subnets
| Network | Subnet | Docker name |
|---|---|---|
| A (client side) | 10.0.1.0/24 | net_a |
| B (middle) | 10.0.2.0/24 | net_b |
| C (server side) | 10.0.3.0/24 | net_c |

## Hosts
| Container | Role | Network | IP |
|---|---|---|---|
| client | runs dig queries | net_a | 10.0.1.10 |
| router1 | router | net_a | 10.0.1.254 |
| router1 | router | net_b | 10.0.2.254 |
| resolver | Unbound | net_b | 10.0.2.10 |
| router2 | router | net_b | 10.0.2.253 |
| router2 | router | net_c | 10.0.3.254 |
| server | BIND9 | net_c | 10.0.3.10 |

## Domain
- Zone: lab.test
- www.lab.test -> 10.0.3.20
- api.lab.test -> 10.0.3.21

## Notes
- Docker reserves .1 on each network as its own gateway, so routers use .254 and .253.
