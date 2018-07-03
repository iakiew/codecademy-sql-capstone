-- 1.a) query for number of distinct campaigns
SELECT COUNT(DISTINCT utm_campaign) AS '# of Campaigns'
FROM page_visits;

-- 1.a) query for number of distinct sources
SELECT COUNT(DISTINCT utm_source) AS '# of Sources'
FROM page_visits;

-- 1.a) query for campaign and source relationship
SELECT DISTINCT utm_campaign AS 'Campaign', 
       utm_source AS 'Source'
FROM page_visits
ORDER BY 2;


-- 1.b) query for what pages are on website
SELECT DISTINCT page_name AS 'Page Type'
FROM page_visits;


-- 2.a) query for first touch per campaign
WITH first_touch AS 
  (
    SELECT user_id,
        MIN(timestamp) as first_touch_at
    FROM page_visits
    GROUP BY user_id
  )
SELECT pv.utm_campaign AS 'Campaign',
    COUNT(ft.first_touch_at) AS '# of 1st Touch'
FROM first_touch AS ft
JOIN page_visits AS pv
    ON ft.user_id = pv.user_id
    AND ft.first_touch_at = pv.timestamp
GROUP BY 1
ORDER BY 2 DESC;

-- 2.a) query for landing page proof
WITH first_touch AS 
  (
    SELECT user_id,
        MIN(timestamp) as first_touch_at
    FROM page_visits
    GROUP BY user_id
  )
SELECT ft.user_id,
       COUNT(pv.page_name) AS '# of Times First Page Visited'
FROM first_touch AS ft
JOIN page_visits AS pv
    ON ft.user_id = pv.user_id
    AND ft.first_touch_at = pv.timestamp
WHERE pv.page_name = '2 - shopping_cart' OR 
      pv.page_name = '3 - checkout' OR
      pv.page_name = '4 - purchase';

-- 2.a) query for users who visited multiple times
SELECT COUNT(page_name) AS '# of Landing Page Visits'
FROM page_visits
WHERE page_name = '1 - landing_page';

SELECT COUNT(DISTINCT user_id) AS '# of Unique Users'
FROM page_visits;

SELECT user_id AS 'USER', 
       COUNT(page_name) AS '# of Landing Page Visits'
FROM page_visits
WHERE page_name = '1 - landing_page'
GROUP BY 1
ORDER BY 2 DESC
LIMIT 50;


-- 2.b) query for last touch per campaign
WITH last_touch AS 
  (
    SELECT user_id,
        MAX(timestamp) as last_touch_at
    FROM page_visits
    GROUP BY user_id
  )
SELECT pv.utm_campaign AS 'Campaign',
    COUNT(lt.last_touch_at) AS '# of Last Touch'
FROM last_touch AS lt
JOIN page_visits AS pv
    ON lt.user_id = pv.user_id
    AND lt.last_touch_at = pv.timestamp
GROUP BY 1
ORDER BY 2 DESC;


-- 2.c) query for how many unique visitors make a purchase
SELECT COUNT(DISTINCT user_id) AS 'Purchasing Users'
FROM page_visits
WHERE page_name = '4 - purchase';

-- 2.c) query for total # of unique visitors
SELECT COUNT(DISTINCT user_id) AS 'Total # of Users'
FROM page_visits;


-- 2.d) query for last touch on purchase page per campaign
WITH last_touch_purchase AS 
  (
    SELECT user_id,
        MAX(timestamp) as last_touch_at
    FROM page_visits
    WHERE page_name = '4 - purchase'
    GROUP BY user_id
  )
SELECT pv.utm_campaign AS 'Campaign',
    COUNT(ltp.last_touch_at) AS '# of Last Touch as Purchase'
FROM last_touch_purchase AS ltp
JOIN page_visits AS pv
    ON ltp.user_id = pv.user_id
    AND ltp.last_touch_at = pv.timestamp
GROUP BY 1
ORDER BY 2 DESC;


-- 2.e) query for user experience
SELECT page_name AS 'Page Type',
       COUNT(DISTINCT user_id) AS '# of Unique Visitors'
FROM page_visits
GROUP BY 1;


-- 2.e) query for users where one campaign takes them from landing to purchase
WITH last_touch_purchase AS 
  (
    SELECT user_id,
           utm_campaign
    FROM page_visits
    WHERE page_name = '4 - purchase' 
  ), 
first_touch_campaign AS 
  (
    SELECT user_id,
           utm_campaign
    FROM page_visits
    WHERE page_name = '1 - landing_page' 
  )
SELECT COUNT(DISTINCT ftc.user_id) AS '# of Users With Complete Single Campaign/Purchase Exp'
FROM last_touch_purchase AS ltp 
LEFT JOIN first_touch_campaign AS ftc
     ON ltp.user_id = ftc.user_id
     AND ltp.utm_campaign = ftc.utm_campaign 
LEFT JOIN page_visits AS pv
     ON ltp.user_id = pv.user_id
     AND ltp.utm_campaign = pv.utm_campaign 
WHERE ftc.user_id IS NOT NULL; --AND

-- this is the underlying data for the above
WITH last_touch_purchase AS 
  (
    SELECT user_id,
           utm_campaign
    FROM page_visits
    WHERE page_name = '4 - purchase' 
  ), 
first_touch_campaign AS 
  (
    SELECT user_id,
           utm_campaign
    FROM page_visits
    WHERE page_name = '1 - landing_page' 
  )
SELECT ftc.user_id AS 'User', 
       pv.utm_campaign AS 'Campaign',
       pv.page_name AS 'Page Type'
FROM last_touch_purchase AS ltp 
LEFT JOIN first_touch_campaign AS ftc
     ON ltp.user_id = ftc.user_id
     AND ltp.utm_campaign = ftc.utm_campaign 
LEFT JOIN page_visits AS pv
     ON ltp.user_id = pv.user_id
     AND ltp.utm_campaign = pv.utm_campaign 
WHERE ftc.user_id IS NOT NULL;


-- 3. query for repeat customers
SELECT user_id AS "User", 
       COUNT(page_name) AS '# of Purchases'
FROM page_visits
WHERE page_name = '4 - purchase'
GROUP BY 1
ORDER by 2 DESC;


-- 3. query for which Acquisition Campaigns took users from landing to shopping cart
WITH second_touch_campaign AS 
  (
    SELECT user_id,
           utm_campaign
    FROM page_visits
    WHERE page_name = '2 - shopping_cart' 
  ), 
first_touch_campaign AS 
  (
    SELECT user_id,
           utm_campaign
    FROM page_visits
    WHERE page_name = '1 - landing_page' 
  )
SELECT pv.utm_campaign AS ‘Acquisition Campaign',
       COUNT(DISTINCT ftc.user_id) AS '# of Users Taken from Landing to Shopping Cart'
FROM second_touch_campaign AS stc 
LEFT JOIN first_touch_campaign AS ftc
     ON stc.user_id = ftc.user_id
     AND stc.utm_campaign = ftc.utm_campaign 
LEFT JOIN page_visits AS pv
     ON stc.user_id = pv.user_id
     AND stc.utm_campaign = pv.utm_campaign 
WHERE ftc.user_id IS NOT NULL
GROUP BY 1
ORDER BY 2 DESC;


-- 3. query for which Acquisition Campaigns took users from shopping cart to checkout
WITH second_touch_campaign AS 
  (
    SELECT user_id,
           utm_campaign
    FROM page_visits
    WHERE page_name = '2 - shopping_cart' 
  ), 
third_touch_campaign AS 
  (
    SELECT user_id,
           utm_campaign
    FROM page_visits
    WHERE page_name = '3 - checkout' 
  )
SELECT pv.utm_campaign AS ‘Acquisition Campaign',
       COUNT(DISTINCT stc.user_id) AS '# of Users Taken from Shopping Cart to Checkout'
FROM second_touch_campaign AS stc 
LEFT JOIN third_touch_campaign AS ttc
     ON stc.user_id = ttc.user_id
     AND stc.utm_campaign = ttc.utm_campaign 
LEFT JOIN page_visits AS pv
     ON stc.user_id = pv.user_id
     AND stc.utm_campaign = pv.utm_campaign 
WHERE ttc.user_id IS NOT NULL
GROUP BY 1
ORDER BY 2 DESC;


-- 3. query for which campaigns took users from checkout to purchase
WITH last_touch_campaign AS 
  (
    SELECT user_id,
           utm_campaign
    FROM page_visits
    WHERE page_name = '4 - purchase' 
  ), 
third_touch_campaign AS 
  (
    SELECT user_id,
           utm_campaign
    FROM page_visits
    WHERE page_name = '3 - checkout' 
  )
SELECT pv.utm_campaign AS 'Campaign',
       COUNT(DISTINCT ttc.user_id) AS '# of Users Taken from Checkout to Purchase'
FROM third_touch_campaign AS ttc 
LEFT JOIN last_touch_campaign AS ltc
     ON ltc.user_id = ttc.user_id
     AND ltc.utm_campaign = ttc.utm_campaign 
LEFT JOIN page_visits AS pv
     ON ttc.user_id = pv.user_id
     AND ttc.utm_campaign = pv.utm_campaign 
WHERE ltc.user_id IS NOT NULL
GROUP BY 1
ORDER BY 2 DESC;

-- 3. this is to check what campaigns show up at which stage

SELECT utm_campaign, page_name
FROM page_visits
WHERE page_name = '1 - landing_page' 
GROUP BY 1;

SELECT utm_campaign, page_name
FROM page_visits
WHERE page_name = '2 - shopping_cart'
GROUP BY 1;

SELECT utm_campaign, page_name
FROM page_visits
WHERE page_name = '3 - checkout' 
GROUP BY 1;

SELECT utm_campaign, page_name
FROM page_visits
WHERE page_name = '4 - purchase'
GROUP BY 1;


-- 3. query for which campaign is responsible for the number of checkout visits
SELECT utm_campaign AS 'Campaign',
       COUNT(user_id) AS '# of Checkout Visits'
FROM page_visits
WHERE page_name = '3 - checkout'
GROUP BY 1
ORDER BY 2 DESC;


-- 3. query for how many purchasing users there are from the interview-with-cool-tshirts-founder Acquisition Campaign

--list of of distinct users touched by the interview campaign
WITH interview_users AS
  (
  SELECT user_id, 
         utm_campaign
  FROM page_visits
  WHERE utm_campaign = 'interview-with-cool-tshirts-founder'
  GROUP BY 1
  )
-- figuring out how many of those users finished a purchase
SELECT COUNT(*) AS '# of Purchasing Users Touched by the Interview Campaign'
FROM interview_users AS iu
JOIN page_visits AS pv
     ON iu.user_id = pv.user_id
WHERE page_name = '4 - purchase';


-- 3. query for how many purchasing users there are from each other Acquisition Campaign

--# of distinct purchasers touched by the getting campaign
WITH getting_users AS
  (
  SELECT user_id, 
         utm_campaign
  FROM page_visits
  WHERE utm_campaign = 'getting-to-know-cool-tshirts'
  GROUP BY 1
  )
SELECT COUNT(*) AS '# of Purchasing Users Touched by the Getting Campaign'
FROM getting_users AS gu
JOIN page_visits AS pv
     ON gu.user_id = pv.user_id
WHERE page_name = '4 - purchase';

--# of distinct purchasers touched by the ten facts campaign
WITH tenfacts_users AS
  (
  SELECT user_id, 
         utm_campaign
  FROM page_visits
  WHERE utm_campaign = 'ten-crazy-cool-tshirts-facts'
  GROUP BY 1
  )
SELECT COUNT(*) AS '# of Purchasing Users Touched by the Ten Facts Campaign'
FROM tenfacts_users AS tu
JOIN page_visits AS pv
     ON tu.user_id = pv.user_id
WHERE page_name = '4 - purchase';

--# of distinct purchasers touched by the organic search campaign
WITH coolsearch_users AS
  (
  SELECT user_id, 
         utm_campaign
  FROM page_visits
  WHERE utm_campaign = 'cool-tshirts-search'
  GROUP BY 1
  )
SELECT COUNT(*) AS '# of Purchasing Users Touched by the Organic Cool Search Campaign'
FROM coolsearch_users AS ou
JOIN page_visits AS pv
     ON ou.user_id = pv.user_id
WHERE page_name = '4 - purchase';
