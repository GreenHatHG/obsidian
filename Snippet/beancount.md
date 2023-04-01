# Check beancount files

```shell
bean-check main.bean
```
 
# Convert a Beancount ledger into an SQL database

```shell
bean-sql main.bean beancount-sqlite
```

# Grafana

## Docker run

```shell
ID=$(id -u)
docker run -d --user $ID -p 3000:3000 \
	--name grafana \
    -v /home/cc/PycharmProjects/beancount/sqlite:/var/lib/grafana \
    -e "GF_SECURITY_ADMIN_USER=admin" \
	-e "GF_SECURITY_ADMIN_PASSWORD=secret" \
	-e "GF_USERS_ALLOW_SIGN_UP=false" \
    grafana/grafana-oss
```

## 开支TOP20

```sql
WITH
cte1 AS ( --三表相连得到必要的列
  SELECT p.id,
         e.date,
         t.payee,
         t.narration,
         p.account,
         t.links,
         SUM(p.number) AS cost
  FROM entry e
  JOIN transactions_detail t ON t.id = e.id
  JOIN postings p ON p.id = e.id
  WHERE p.account LIKE "Expenses%"
  and strftime('%s', e.date) * 1000 >= $__from AND strftime('%s', e.date) * 1000 <= $__to
  GROUP BY p.id,
           e.date,
           t.payee,
           t.narration,
           p.account
),
cte2 AS ( --cte1表自连接，根据links相加cost列
  SELECT c1.id,
         c1.date,
         c1.payee,
         c1.narration,
         c1.account,
         c1.links,
         c1.cost + c2.cost AS cost
  FROM cte1 c1
  INNER JOIN cte1 c2
  WHERE c1.links = c2.links
    AND c1.links != ""
  GROUP BY c1.links
),
cte3 AS ( --cte1表cte2合并，目的是更新cte1的cost列的值
  SELECT *
  FROM cte2
  UNION ALL
  SELECT *
  FROM cte1
), cte4 as (
    SELECT DISTINCT id,
                    date,
                    (case when payee is not null then "[" || payee || "]-" else "" end)
                        || "[" || narration || "]" || "  " || strftime('%Y-%m-%d',date) as item,
                    cost
    FROM cte3
    GROUP BY id
    ORDER BY cost DESC LIMIT 20
)
select item, cost from cte4
```