#!/usr/bin/env python3
from db2pq import wrds_update_pq

wrds_update_pq("ciqfininstance", "ciq")
wrds_update_pq("ciqfinperiod", "ciq")
wrds_update_pq("ciqgvkeyiid", "ciq")
wrds_update_pq("ciqfincollection", "ciq")
wrds_update_pq("ciqfininstancetocollection", "ciq")
