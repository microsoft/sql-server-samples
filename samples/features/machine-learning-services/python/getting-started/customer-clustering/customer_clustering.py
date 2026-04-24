# Load packages.
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import revoscalepy as revoscale
from scipy.spatial import distance as sci_distance
from sklearn import cluster as sk_cluster



def perform_clustering():
    ################################################################################################

    ##	Connect to DB and select data

    ################################################################################################

    # Connection string to connect to SQL Server named instance.
    conn_str = 'Driver=SQL Server;Server=localhost;Database=tpcxbb_1gb;Trusted_Connection=True;'

    input_query = '''SELECT
    ss_customer_sk AS customer,
    ROUND(COALESCE(returns_count / NULLIF(1.0*orders_count, 0), 0), 7) AS orderRatio,
    ROUND(COALESCE(returns_items / NULLIF(1.0*orders_items, 0), 0), 7) AS itemsRatio,
    ROUND(COALESCE(returns_money / NULLIF(1.0*orders_money, 0), 0), 7) AS monetaryRatio,
    COALESCE(returns_count, 0) AS frequency
    FROM
    (
      SELECT
        ss_customer_sk,
        -- return order ratio
        COUNT(distinct(ss_ticket_number)) AS orders_count,
        -- return ss_item_sk ratio
        COUNT(ss_item_sk) AS orders_items,
        -- return monetary amount ratio
        SUM( ss_net_paid ) AS orders_money
      FROM store_sales s
      GROUP BY ss_customer_sk
    ) orders
    LEFT OUTER JOIN
    (
      SELECT
        sr_customer_sk,
        -- return order ratio
        count(distinct(sr_ticket_number)) as returns_count,
        -- return ss_item_sk ratio
        COUNT(sr_item_sk) as returns_items,
        -- return monetary amount ratio
        SUM( sr_return_amt ) AS returns_money
    FROM store_returns
    GROUP BY sr_customer_sk ) returned ON ss_customer_sk=sr_customer_sk'''


    # Define the columns we wish to import.
    column_info = {
        "customer": {"type": "integer"},
        "orderRatio": {"type": "integer"},
        "itemsRatio": {"type": "integer"},
        "frequency": {"type": "integer"}
    }

    data_source = revoscale.RxSqlServerData(sql_query=input_query, column_info=column_info,
                                              connection_string=conn_str)

    # import data source and convert to pandas dataframe.
    customer_data = pd.DataFrame(revoscalepy.rx_import(data_source))
    print("Data frame:", customer_data.head(n=20))

    ################################################################################################

    ##	Determine number of clusters using the Elbow method

    ################################################################################################

    cdata = customer_data
    K = range(1, 20)
    KM = (sk_cluster.KMeans(n_clusters=k).fit(cdata) for k in K)
    centroids = (k.cluster_centers_ for k in KM)

    D_k = (sci_distance.cdist(cdata, cent, 'euclidean') for cent in centroids)
    dist = (np.min(D, axis=1) for D in D_k)
    avgWithinSS = [sum(d) / cdata.shape[0] for d in dist]
    plt.plot(K, avgWithinSS, 'b*-')
    plt.grid(True)
    plt.xlabel('Number of clusters')
    plt.ylabel('Average within-cluster sum of squares')
    plt.title('Elbow for KMeans clustering')
    plt.show()


    ################################################################################################

    ##	Perform clustering using Kmeans

    ################################################################################################

    # It looks like k=4 is a good number to use based on the elbow graph.
    n_clusters = 4

    means_cluster = sk_cluster.KMeans(n_clusters=n_clusters, random_state=111)
    columns = ["orderRatio", "itemsRatio", "monetaryRatio", "frequency"]
    est = means_cluster.fit(customer_data[columns])
    clusters = est.labels_
    customer_data['cluster'] = clusters

    # Print some data about the clusters:

    # For each cluster, count the members.
    for c in range(n_clusters):
        cluster_members=customer_data[customer_data['cluster'] == c][:]
        print('Cluster{}(n={}):'.format(c, len(cluster_members)))
        print('-'* 17)

    # Print mean values per cluster.
    print(customer_data.groupby(['cluster']).mean())


perform_clustering()

