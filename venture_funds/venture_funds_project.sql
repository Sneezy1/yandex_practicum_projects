1. Число закрытых компаний 

SELECT COUNT(id)
FROM company
WHERE status= 'closed'

2. Количество привлеченных средств для новостных компаний из США

SELECT funding_total
from company
WHERE category_code ='news' AND country_code = 'USA'
ORDER BY funding_total DESC

3. Общая сумма сделок при покупке одних компаний другими за наличные с 2011 по 213 годы.

SELECT SUM(price_amount)
FROM acquisition
WHERE term_code='cash' AND EXTRACT(YEAR FROM acquired_at) BETWEEN 2011 AND 2013

4. Имя, Фамилия и названия аккунтов людей в твиттере с 'silver' в названии аккаунта

SELECT first_name, last_name, twitter_username
FROM people
WHERE twitter_username LIKE 'Silver%'

5. Вся информация о людях у которых название аккаунта содержит 'money' и фамилия начинается на 'K'

SELECT *
FROM people
WHERE last_name LIKE 'K%' AND twitter_username LIKE '%money%'

6. Сумма привлеченных инвестиций для каждой страны, привличенных компаниями в данной стране

SELECT country_code, SUM(funding_total)
FROM company
GROUP BY country_code
ORDER BY SUM(funding_total) DESC

7. Дата проведения раунда, минимальное и максимальное значение суммы инвестиций в эту дату. Минимальное значение не ранво нулю и не равно максимальному.

SELECT funded_at, MAX(raised_amount), MIN(raised_amount)
FROM funding_round
GROUP BY funded_at
HAVING MIN(raised_amount) != 0 AND MIN(raised_amount) != MAX(raised_amount)


8. Создать поля с категориями для фондов, которые инвестировали в 100 и более компаний, инвестировали в 20 до 100, менее чем в 20 компаний

SELECT *, 
CASE
WHEN  invested_companies >= 100 THEN 'high_activity'
WHEN invested_companies >= 20 AND invested_companies < 100 THEN 'middle_activity'
WHEN invested_companies < 20 THEN 'low_activity'
END
FROM fund

9. Посчитайте для каждой категории из предыдущего запроса посчитать округленное до целого среднее количество инвестиционных раундов, в которых фонд принимал участие. Вывести категории и среднее чисто раундов

WITH first as(SELECT *,
       CASE
           WHEN invested_companies>=100 THEN 'high_activity'
           WHEN invested_companies>=20 THEN 'middle_activity'
           ELSE 'low_activity'
       END AS activity
FROM fund)
SELECT activity, ROUND(AVG(investment_rounds))
FROM first
GROUP BY activity
ORDER BY AVG(investment_rounds)

10. Таблица с 10 самыми активными странами-инвесторами. Для каждой страны минимальное, среднее и максимальное число компаний, в которые инвестировали фонды, основанные с 2010 по 2012. Исключить страны с минимальным числом фондов равным нулю.


SELECT country_code, MIN(invested_companies), MAX(invested_companies), AVG(invested_companies)
FROM fund
WHERE EXTRACT(YEAR from founded_at) BETWEEN 2010 AND 2012
AND country_code IN (SELECT country_code
FROM fund
GROUP BY country_code
ORDER BY AVG(invested_companies) DESC)
GROUP BY  country_code
HAVING MIN(invested_companies) != 0
ORDER BY AVG(invested_companies) DESC
LIMIT 10

11. Имя и фамилия всех сотрудников стартапов, добавить учебное заведение, если есть.

select first_name, last_name, instituition
FROM people LEFT OUTER JOIN education on people.id = education.person_id


12. Для каждой компании найти число учебных заведений которые окончили её сотрудники. Составьте топ-5 компаний.

select c.name, COUNT(DISTINCT instituition)
FROM company as c INNER JOIN people as p ON p.company_id = c.id
INNER JOIN education as e ON e.person_id = p.id
group BY c.name
ORDER BY COUNT(DISTINCT instituition) DESC
LIMIT 5


13. Список с уникальными названиями закрытых компаний, для которых первый раунд финансирования оказался последним

SELECT DISTINCT name
FROM company c INNER JOIN funding_round fd ON c.id= fd.company_id
WHERE is_last_round = 1  AND is_first_round = 1 
AND status = 'closed'

14. Список уникальных номеров сотрудников, которые работают в компаниях из 13 пункта

SELECT DISTINCT p.id
FROM people p INNER JOIN company c on p.company_id = c.id
WHERE c.name IN (SELECT DISTINCT name
FROM company c INNER JOIN funding_round fd ON c.id= fd.company_id
WHERE is_last_round = 1  AND is_first_round = 1 
AND status = 'closed')


15. Уникальные пары с номером сотрудников из 14 пункта и учебным заведением

SELECT DISTINCT p.id, instituition
FROM people p INNER JOIN education e on e.person_id = p.id
WHERE p.id IN (SELECT DISTINCT p.id
FROM people p INNER JOIN company c on p.company_id = c.id
WHERE c.name IN (SELECT DISTINCT name
FROM company c INNER JOIN funding_round fd ON c.id= fd.company_id
WHERE is_last_round = 1  AND is_first_round = 1 
AND status = 'closed'))

16. Количестов учебных заведений для каждого сотрудника из 15 пункта

WITH rq AS (SELECT p.id, instituition
FROM people p INNER JOIN education e on e.person_id = p.id
WHERE p.id IN (SELECT DISTINCT p.id
FROM people p INNER JOIN company c on p.company_id = c.id
WHERE c.name IN (SELECT DISTINCT name
FROM company c INNER JOIN funding_round fd ON c.id= fd.company_id
WHERE is_last_round = 1  AND is_first_round = 1 
AND status = 'closed')))
SELECT COUNT(instituition), id
FROM rq
GROUP BY id

17. Дополнить запрос из пункта 16 и вывести среднее число учебных заведений, которые окончили сотрудники разных компаний.

WITH rq AS (SELECT p.id, instituition
FROM people p INNER JOIN education e on e.person_id = p.id
WHERE p.id IN (SELECT DISTINCT p.id
FROM people p INNER JOIN company c on p.company_id = c.id
WHERE c.name IN (SELECT DISTINCT name
FROM company c INNER JOIN funding_round fd ON c.id= fd.company_id
WHERE is_last_round = 1  AND is_first_round = 1 
AND status = 'closed'))),
er AS
(SELECT COUNT(instituition), id
FROM rq
GROUP BY id)
SELECT AVG(count) FROM er

18. Среднее число учебных заведений, которые окончили сотрудники Facebook

WITH rq AS (SELECT p.id, instituition
FROM people p INNER JOIN education e on e.person_id = p.id
WHERE p.id IN (SELECT DISTINCT p.id
FROM people p INNER JOIN company c on p.company_id = c.id
WHERE c.name IN ('Facebook'))),
er AS
(SELECT COUNT(instituition), id
FROM rq
GROUP BY id)
SELECT AVG(count) FROM er

19. Таблица из полей: название фонда, название компании, сумма инвестиций. Компании, у которых более 6 важных этапов, а раунды финансирования проходили с 2012 по 2013

SELECT f.name AS name_of_fund,
    c.name AS name_of_company,
    fr.raised_amount AS amount    
FROM investment i JOIN company c ON i.company_id = c.id
LEFT JOIN fund f ON i.fund_id = f.id  
LEFT JOIN funding_round fr ON i.funding_round_id = fr.id
WHERE c.milestones > 6 AND EXTRACT(YEAR FROM fr.funded_at) BETWEEN 2012 AND 2013
GROUP BY f.name, c.name, fr.raised_amount;


20. Таблица из полей: названи компании-покупателя, сумма сделки, название купленной компании, сумма инвестиций вложенных в купленную компанию, доля, отображающая во сколько сумма покупки превысила сумму вложенных инвестиций, округленная до целого. Не учитывать сделки с суммой, равной нулю. Ну учитывать компании с суммой инвестиций равной нулю.

SELECT c1.name, a.price_amount, c2.name, c2.funding_total, ROUND(a.price_amount / c2.funding_total)
FROM acquisition a LEFT JOIN company as c1 on a.acquiring_company_id = c1.id
LEFT JOIN company as c2 on a.acquired_company_id = c2.id
WHERE a.price_amount != 0 AND c2.funding_total != 0
ORDER BY a.price_amount DESC, c2.name ASC
LIMIT 10



21. Таблица из полей: названия компании из категории social, номер месяца. Компании, получшившие финансирование с 2010 по 2013


SELECT c.name, EXTRACT(MONTH FROM funded_at)
FROM company c JOIN funding_round as fr on c.id = fr.company_id
WHERE category_code = 'social' AND EXTRACT(YEAR FROM funded_at) BETWEEN 2010 AND 2013

22. Данные с 2010 по 2013 год, когда проходили инвестиционные раунды. Таблица с полями: номер месяца, количество, уникальных названий фондов из США, инвестировавших в этом месяце, количество купленных за этот месяц компаний, 
общая сумма сделок по покупкам в этом месяце

WITH f1 AS (SELECT EXTRACT(MONTH FROM funded_at) mon, COUNT(DISTINCT f.name) cntf
FROM funding_round fr JOIN investment i on i.funding_round_id = fr.id
LEFT JOIN fund f on f.id = i.fund_id
WHERE EXTRACT(YEAR FROM funded_at) BETWEEN 2010 AND 2013 AND f.country_code = 'USA'
GROUP BY EXTRACT(MONTH FROM funded_at)),

f2 AS (SELECT EXTRACT(MONTH FROM acquired_at) as mon, COUNT(acquired_company_id) cntc, SUM(price_amount) sump
FROM acquisition
WHERE EXTRACT(YEAR FROM acquired_at) BETWEEN 2010 AND 2013
GROUP BY EXTRACT(MONTH FROM acquired_at))
SELECT f2.mon, cntf, cntc, sump FROM f1 JOIN f2 on f1.mon = f2.mon


23. Сводная таблица со средней суммой инвестиций для стран в которых есть стартапы, зарегистрированные в 2011, 2012, 2013. Данные за каждый год в отдельном поле. 

with t1 as(SELECT country_code c1, AVG(funding_total) t2011
FROM company
WHERE EXTRACT(YEAR FROM founded_at) = 2011
GROUP BY country_code),
t2 as(SELECT country_code c2, AVG(funding_total) t2012
FROM company
WHERE EXTRACT(YEAR FROM founded_at) = 2012
GROUP BY country_code),
t3 as(SELECT country_code c3, AVG(funding_total) t2013
FROM company
WHERE EXTRACT(YEAR FROM founded_at) = 2013
GROUP BY country_code)
SELECT c1, t2011, t2012, t2013
FROM t1 inner join t2 on t1.c1 = t2.c2
INNER JOIN t3 on t2.c2 = t3.c3
ORDER BY t2011 DESC