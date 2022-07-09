# Introduction
Puppet is a open source software configuration management and deployment tool. It solves system administrators' problems working with multiple servers by automating the IT infrastructure, and ensuring that all systems are configured to a desired and predictable state. Puppet is written in Ruby, a highly objectoriented programming language.

Lately, in 2022 the company Puppetlabs has been acquired by Perforce - a leading provider of highly scalable development and DevOps solutions.
The goal of a new tools for Kubernetes and cloud native apps resulted already in a market consolidation of independent configuration management vendors , eg. Chef has been Acquired by Progress, Ansible has been bought by IBM, and Saltstack has been bought by VMware in 2020.  The focus on making data center and cloud infrastructure easily consumable and facing the multi-cloud adoption challenges, the competitor Hashicorp gained between 2015 until 2022 more traction with their products Terraform, Packer, Vault, etc. than Puppet did before. Today the Puppet community embraced the Hashicorp tools at forge.puppet.com.

I had an interesting talk to Roger Widmer, IT infrastructure expert at MeteoSwiss. He convinced me to get familiar with puppet. MeteoSwiss produces climate information. Engineers do environmental science (environmental and climate change modeling, glacier studies, urban hydrological modeling, meteorological studies) and for their work baremetal performance cpu/gpu/storage/ram is critical.

Here some related weather observations weblinks:
COSMO, Consortium for small scale modeling: https://www.cosmo-model.org/content/support/software/default.htm
Snowmelt modeling: https://wiki.c2sm.ethz.ch/pub/MODELS/COSMOCuW2019/3_COSMO_User_Workshop_19_TJonas.pdf
MeteoSwiss Payerne Atmospheric Observatory: http://srnwp.cosmo-model.org/archive/Payerne/support/metadata.pdf
COSMO Transition to ICON, C2I : https://www.cosmo-model.org/content/support/icon/default.htm, https://www.cosmo-model.org/content/consortium/generalMeetings/general2021/parallel/wg6-c2i/C2I_COSMO-GM_Introduction.pdf
NinJo Meteorological Workstation: [http://www.ninjo-workstation.com/](http://www.ninjo-workstation.com/project-members.0.html)
Abstractions for Weather and Climate Models: https://pasc17.pasc-conference.org/fileadmin/user_upload/pasc17/program/MS21.pdf

Roger explained that the puppet enterprise platform powers all MeteoSwiss weather observations related workstations and server farms. For the planned datacenter projects - new geolocation and adoption to multi-cloud - business continuity management is a main topic. 

# Multi-Cloud

