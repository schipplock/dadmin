-- -------------------------------------------------------------------------------
-- "THE BEER-WARE LICENSE" (Revision 42):
-- <andreas@schipplock.de> wrote this file. As long as you retain this notice you
-- can do whatever you want with this stuff. If we meet some day, and you think
-- this stuff is worth it, you can buy me a beer in return Andreas Schipplock
-- -------------------------------------------------------------------------------

-- 
-- drop all sequences
--
drop sequence if exists topleveldomains_seq;
drop sequence if exists status_seq;
drop sequence if exists pricegroups_seq;
drop sequence if exists prices_seq;
drop sequence if exists users_seq;
drop sequence if exists domainnames_seq;

--
-- drop all defined functions
-- 
drop function if exists status_get_pagecount();
drop function if exists status_results(pagenumber integer);
drop function if exists pricegroups_get_pagecount();
drop function if exists pricegroups_results(pagenumber integer);
drop function if exists prices_get_pagecount();
drop function if exists prices_results(pagenumber integer);
drop function if exists price_get_topleveldomain(price_id integer);
drop function if exists price_get_pricegroup(price_id integer);
drop function if exists users_get_pagecount();
drop function if exists users_results(pagenumber integer);
drop function if exists user_get_pricegroup(user_id integer);
drop function if exists domainnames_get_pagecount(the_user_id integer, domainsearchstring varchar);
drop function if exists domainnames_results(pagenumber integer, the_user_id integer, domainsearchstring varchar);
drop function if exists domainnames_user_get_pagecount(the_user_id integer);
drop function if exists domainnames_user_results(pagenumber integer, the_user_id integer);
drop function if exists user_get_overall_domain_costs(the_user_id integer);
drop function if exists domain_expire_check(the_user_id integer, months_above integer);

--
-- drop all defined types
--
drop type if exists status_type;
drop type if exists pricegroup_type;
drop type if exists price_type;
drop type if exists price_topleveldomain;
drop type if exists price_pricegroup;
drop type if exists user_type;
drop type if exists user_pricegroup;
drop type if exists domainname_type;
drop type if exists domainname_user_type;
drop type if exists domain_expire_type;

--
-- drop the language
--
drop language plpgsql;

-- 
-- drop all tables
--
drop table if exists domainnames;
drop table if exists prices;
drop table if exists topleveldomains;
drop table if exists status;
drop table if exists users;
drop table if exists pricegroups;

-- 
-- create all needed sequences
-- 
create sequence topleveldomains_seq minvalue 1 start with 1 increment by 1 no cycle;
create sequence status_seq minvalue 1 start with 1 increment by 1 no cycle;
create sequence pricegroups_seq minvalue 1 start with 1 increment by 1 no cycle;
create sequence prices_seq minvalue 1 start with 1 increment by 1 no cycle;
create sequence users_seq minvalue 1 start with 1 increment by 1 no cycle;
create sequence domainnames_seq minvalue 1 start with 1 increment by 1 no cycle;

-- 
-- create the tables
--

create table topleveldomains (
	id integer primary key,
	domain varchar(10)
);

create table status (
	id integer primary key,
	code integer not null,
	description varchar(100)
);

create table pricegroups (
	id integer primary key,
	name varchar(100) unique not null,
	description varchar(255)
);

create table prices (
	id integer primary key,
	topleveldomain_id integer not null,
	pricegroup_id integer not null,
	baseprice float not null,
	salesprice float not null,
	constraint topleveldomain_prices_fk foreign key(topleveldomain_id) references topleveldomains(id),
	constraint pricegroup_prices_fk foreign key(pricegroup_id) references pricegroups(id)
);

create table users (
	id integer primary key,
	pricegroup_id integer not null,
	username varchar(100) unique not null,
	groups varchar(100) not null,
	password varchar(255) not null,
	firstname varchar(100) not null,
	lastname varchar(100) not null,
	company varchar(100),
	country varchar(100),
	city varchar(100),
	zipcode int,
	street varchar(100),
	phone varchar(100),
	mobile varchar(100),
	email varchar(100) unique not null,
	constraint pricegroup_users_fk foreign key(pricegroup_id) references pricegroups(id)
);

create table domainnames (
	id integer primary key,
	user_id integer not null,
	domainname varchar(255) not null,
	topleveldomain_id integer not null,
	registrationdate date not null,
	validity smallint not null default 1,
	autorenew boolean default true,
	status_id integer not null,
	constraint user_domainnames_fk foreign key(user_id) references users(id),
	constraint topleveldomain_domainnames_fk foreign key(topleveldomain_id) references topleveldomains(id),
	constraint status_domainnames_fk foreign key(status_id) references status(id)
);

-- 
-- insert some topleveldomains
--
insert into topleveldomains (id,domain) values (nextval('topleveldomains_seq'), 'com');
insert into topleveldomains (id,domain) values (nextval('topleveldomains_seq'), 'net');
insert into topleveldomains (id,domain) values (nextval('topleveldomains_seq'), 'org');
insert into topleveldomains (id,domain) values (nextval('topleveldomains_seq'), 'de');

-- 
-- insert the administrator set
--
insert into pricegroups (id,name) values (nextval('pricegroups_seq'), 'Admin-Pricegroup');

-- 
-- insert some topleveldomains
--
insert into prices (id,topleveldomain_id,pricegroup_id,baseprice,salesprice) values (nextval('prices_seq'), 1, currval('pricegroups_seq'), 8.00, 8.00); --com
insert into prices (id,topleveldomain_id,pricegroup_id,baseprice,salesprice) values (nextval('prices_seq'), 2, currval('pricegroups_seq'), 8.00, 8.00); --net
insert into prices (id,topleveldomain_id,pricegroup_id,baseprice,salesprice) values (nextval('prices_seq'), 3, currval('pricegroups_seq'), 8.00, 8.00); --org
insert into prices (id,topleveldomain_id,pricegroup_id,baseprice,salesprice) values (nextval('prices_seq'), 4, currval('pricegroups_seq'), 6.00, 6.00); --de

insert into users (id,pricegroup_id,username,groups,password,firstname,lastname,email) values (nextval('users_seq'), currval('pricegroups_seq'), 'admin', 'admin', md5('admin'), 'Ad', 'Min', 'admin@example.com');

--
-- my functions for STATUS
--

-- create a specific type here
create type status_type as (
	id integer,
	code integer,
	description varchar(100),
	domains_associated integer
);

create language plpgsql;

-- FUNCTION : returns the number of possible pages (used for paging) 
create function status_get_pagecount() returns integer as $$
declare
	pagecount integer;
	pagesize integer default 5;
begin
	select count(id)/pagesize into pagecount from status;
	if ((select count(id)%pagesize from status)>0) then 
		pagecount := pagecount+1;
	end if;
	return pagecount;
end;
$$ language 'plpgsql';

-- FUNCTION : returns the results for a given "page"
create function status_results(pagenumber integer)returns setof status_type as $$
declare
	r record;
	foo status_type;
	pagesize integer default 5;
begin
	for r in 
	  select id,code,description, (select count(domainnames.id) from domainnames where domainnames.status_id=id) as domains_associated from status order by id limit pagesize offset ((pagenumber-1)*pagesize)
	loop
		foo.id := r.id;
		foo.code := r.code;
		foo.description := r.description;
		foo.domains_associated := r.domains_associated;
		return next foo;
	end loop;
	return;
end;
$$ language 'plpgsql';

-- some tests
-- select id,code,description from status_results(5); 
-- select id,code,description from status_results(1); 
-- select * from status_get_pagecount();



--
-- my functions for PRICEGROUPS
--

-- create a specific type here
create type pricegroup_type as (
	id integer,
	name varchar(100),
	users_associated integer
);

-- FUNCTION : returns the number of possible pages (used for paging) 
create function pricegroups_get_pagecount() returns integer as $$
declare
	pagecount integer;
	pagesize integer default 5;
begin
	select count(id)/pagesize into pagecount from pricegroups;
	if ((select count(id)%pagesize from pricegroups)>0) then 
		pagecount := pagecount+1;
	end if;
	return pagecount;
end;
$$ language 'plpgsql';

-- FUNCTION : returns the results for a given "page"
create function pricegroups_results(pagenumber integer) returns setof pricegroup_type as $$
declare
	r record;
	foo pricegroup_type;
	pagesize integer default 5;
begin
	for r in 
	  select id,name, (select count(users.id) from users where users.pricegroup_id=pricegroups.id) as users_associated from pricegroups order by id limit pagesize offset ((pagenumber-1)*pagesize)
	loop
		foo.id := r.id;
		foo.name := r.name;
		foo.users_associated := r.users_associated;
		return next foo;
	end loop;
	return;
end;
$$ language 'plpgsql';






--
-- my functions for PRICES
--

-- create a specific type here
create type price_type as (
	id integer,
	domain varchar(10),
	domain_id integer,
	pricegroup varchar(100),
	pricegroup_id integer,
	baseprice float,
	salesprice float
);

-- FUNCTION : returns the number of possible pages (used for paging) 
create function prices_get_pagecount() returns integer as $$
declare
	pagecount integer;
	pagesize integer default 5;
begin
	select count(id)/pagesize into pagecount from prices;
	if ((select count(id)%pagesize from prices)>0) then 
		pagecount := pagecount+1;
	end if;
	return pagecount;
end;
$$ language 'plpgsql';

-- FUNCTION : returns the results for a given "page"
create function prices_results(pagenumber integer) returns setof price_type as $$
declare
	r record;
	foo price_type;
	pagesize integer default 5;
begin
	for r in 
	  select id,(select topleveldomains.domain from topleveldomains where topleveldomains.id=prices.topleveldomain_id) as domain, topleveldomain_id as domain_id, (select pricegroups.name from pricegroups where pricegroups.id=prices.pricegroup_id) as pricegroup, pricegroup_id, baseprice, salesprice from prices order by id limit pagesize offset ((pagenumber-1)*pagesize)
	loop
		foo.id := r.id;
		foo.domain := r.domain;
		foo.domain_id := r.domain_id;
		foo.pricegroup := r.pricegroup;
		foo.pricegroup_id := r.pricegroup_id;
		foo.baseprice := r.baseprice;
		foo.salesprice := r.salesprice;
		return next foo;
	end loop;
	return;
end;
$$ language 'plpgsql';

-- FUNCTION : returns the topleveldomain ID and topleveldomain NAME for a given price id
create type price_topleveldomain as (
	id integer,
	domain varchar(255)
);

create function price_get_topleveldomain(price_id integer) returns price_topleveldomain as $$
declare
	foo price_topleveldomain;
begin
	select topleveldomain_id as id,(select domain from topleveldomains where topleveldomains.id=prices.topleveldomain_id) as domain into foo from prices where id=price_id;
	return foo;
end;
$$ language 'plpgsql';

-- example: select id,domain from price_get_topleveldomain(6);


-- FUNCTION : returns the pricegroup ID and pricegroup NAME for a given price id

create type price_pricegroup as (
	id integer,
	name varchar(100)
);

create function price_get_pricegroup(price_id integer) returns price_pricegroup as $$
declare
	foo price_pricegroup;
begin
	select pricegroup_id as id,(select name from pricegroups where pricegroups.id=prices.pricegroup_id) as name into foo from prices where id=price_id;
	return foo;
end;
$$ language 'plpgsql';

-- example: select id,name from price_get_pricegroup(6);



--
-- my functions for USERS
--

-- create a specific type here
create type user_type as (
	id integer,
	username varchar(100),
	firstname varchar(100),
	lastname varchar(100),
	email varchar(100),
	phone varchar(100),
	pricegroup_name varchar(100),
	pricegroup_id integer,
	domaincount integer
);

-- FUNCTION : returns the number of possible pages (used for paging) 
create function users_get_pagecount() returns integer as $$
declare
	pagecount integer;
	pagesize integer default 5;
begin
	select count(id)/pagesize into pagecount from users;
	if ((select count(id)%pagesize from users)>0) then 
		pagecount := pagecount+1;
	end if;
	return pagecount;
end;
$$ language 'plpgsql';

-- FUNCTION : returns the results for a given "page"
create function users_results(pagenumber integer) returns setof user_type as $$
declare
	r record;
	foo user_type;
	pagesize integer default 5;
begin
	for r in 
	  select id,username,firstname,lastname,email,phone,(select name from pricegroups where pricegroups.id=users.pricegroup_id) as pricegroup_name, pricegroup_id, (select count(id) from domainnames where domainnames.user_id=users.id) as domaincount from users order by id limit pagesize offset ((pagenumber-1)*pagesize)
	loop
		foo.id := r.id;
		foo.username := r.username;
		foo.firstname := r.firstname;
		foo.lastname := r.lastname;
		foo.email := r.email;
		foo.phone := r.phone;
		foo.pricegroup_name := r.pricegroup_name;
		foo.pricegroup_id := r.pricegroup_id;
		foo.domaincount := r.domaincount;
		return next foo;
	end loop;
	return;
end;
$$ language 'plpgsql';

-- FUNCTION : returns the pricegroup ID and pricegroup NAME for a given user id
create type user_pricegroup as (
	id integer,
	name varchar(100)
);

create function user_get_pricegroup(user_id integer) returns user_pricegroup as $$
declare
	foo user_pricegroup;
begin
	select pricegroup_id,(select name from pricegroups where pricegroups.id=users.pricegroup_id) as name into foo from users where id=user_id;
	return foo;
end;
$$ language 'plpgsql';




--
-- my functions for DOMAINNAMES
--

-- create a specific type here
create type domainname_type as (
	id integer,
	domainname varchar(255),
	topleveldomain varchar(10),
	username varchar(100),
	registrationdate date,
	validity integer,
	autorenew boolean,
	status_code integer,
	status_name varchar(100),
	costs float
);

-- FUNCTION : returns the number of possible pages (used for paging) 
create function domainnames_get_pagecount(the_user_id integer, domainsearchstring varchar) returns integer as $$
declare
	pagecount integer;
	pagesize integer default 5;
begin
	if (domainsearchstring = null) then
		if (the_user_id = 1) then
			select count(id)/pagesize into pagecount from domainnames;
			if ((select count(id)%pagesize from domainnames)>0) then 
				pagecount := pagecount+1;
			end if;
			return pagecount;
		else 
			select count(id)/pagesize into pagecount from domainnames where domainnames.user_id=the_user_id;
			if ((select count(id)%pagesize from domainnames where domainnames.user_id=the_user_id)>0) then 
				pagecount := pagecount+1;
			end if;
			return pagecount;
		end if;
	else 
		if (the_user_id = 1) then
			select count(id)/pagesize into pagecount from domainnames where domainname like '%'||domainsearchstring||'%';
			if ((select count(id)%pagesize from domainnames where domainname like '%'||domainsearchstring||'%')>0) then 
				pagecount := pagecount+1;
			end if;
			return pagecount;
		else 
			select count(id)/pagesize into pagecount from domainnames where domainnames.user_id=the_user_id and domainname like '%'||domainsearchstring||'%';
			if ((select count(id)%pagesize from domainnames where domainnames.user_id=the_user_id and domainnames.domainname like '%'||domainsearchstring||'%')>0) then 
				pagecount := pagecount+1;
			end if;
			return pagecount;
		end if;
	end if;
end;
$$ language 'plpgsql';

-- FUNCTION : returns the results for a given "page"
create function domainnames_results(pagenumber integer, the_user_id integer, domainsearchstring varchar) returns setof domainname_type as $$
declare
	r record;
	foo domainname_type;
	pagesize integer default 5;
begin
	if (domainsearchstring = null) then
		if (the_user_id = 1) then
			for r in 
			  select id,domainname,(select domain from topleveldomains where topleveldomains.id=domainnames.topleveldomain_id) as topleveldomain,(select username from users where users.id=domainnames.user_id) as username,registrationdate,validity,autorenew,(select code from status where status.id=domainnames.status_id) as status_code, (select description from status where status.id=domainnames.status_id) as status_name, (select baseprice from prices where prices.topleveldomain_id=domainnames.topleveldomain_id and prices.pricegroup_id=(select pricegroup_id from users where users.id=domainnames.user_id)) as costs from domainnames order by id limit pagesize offset ((pagenumber-1)*pagesize)
			loop
				foo.id := r.id;
				foo.domainname := r.domainname;
				foo.topleveldomain := r.topleveldomain;
				foo.username := r.username;
				foo.registrationdate := r.registrationdate;
				foo.validity := r.validity;
				foo.autorenew := r.autorenew;
				foo.status_code := r.status_code;
				foo.status_name := r.status_name;
				foo.costs := r.costs;
				return next foo;
			end loop;
			return;
		else
			for r in 
			  select id,domainname,(select domain from topleveldomains where topleveldomains.id=domainnames.topleveldomain_id) as topleveldomain,(select username from users where users.id=domainnames.user_id) as username,registrationdate,validity,autorenew,(select code from status where status.id=domainnames.status_id) as status_code, (select description from status where status.id=domainnames.status_id) as status_name, (select baseprice from prices where prices.topleveldomain_id=domainnames.topleveldomain_id and prices.pricegroup_id=(select pricegroup_id from users where users.id=domainnames.user_id)) as costs from domainnames where domainnames.user_id=the_user_id order by id limit pagesize offset ((pagenumber-1)*pagesize)
			loop
				foo.id := r.id;
				foo.domainname := r.domainname;
				foo.topleveldomain := r.topleveldomain;
				foo.username := r.username;
				foo.registrationdate := r.registrationdate;
				foo.validity := r.validity;
				foo.autorenew := r.autorenew;
				foo.status_code := r.status_code;
				foo.status_name := r.status_name;
				foo.costs := r.costs;
				return next foo;
			end loop;
			return;
		end if;
	else 
		if (the_user_id = 1) then
			for r in 
			  select id,domainname,(select domain from topleveldomains where topleveldomains.id=domainnames.topleveldomain_id) as topleveldomain,(select username from users where users.id=domainnames.user_id) as username,registrationdate,validity,autorenew,(select code from status where status.id=domainnames.status_id) as status_code, (select description from status where status.id=domainnames.status_id) as status_name, (select baseprice from prices where prices.topleveldomain_id=domainnames.topleveldomain_id and prices.pricegroup_id=(select pricegroup_id from users where users.id=domainnames.user_id)) as costs from domainnames where domainnames.domainname like '%'||domainsearchstring||'%' order by id limit pagesize offset ((pagenumber-1)*pagesize)
			loop
				foo.id := r.id;
				foo.domainname := r.domainname;
				foo.topleveldomain := r.topleveldomain;
				foo.username := r.username;
				foo.registrationdate := r.registrationdate;
				foo.validity := r.validity;
				foo.autorenew := r.autorenew;
				foo.status_code := r.status_code;
				foo.status_name := r.status_name;
				foo.costs := r.costs;
				return next foo;
			end loop;
			return;
		else
			for r in 
			  select id,domainname,(select domain from topleveldomains where topleveldomains.id=domainnames.topleveldomain_id) as topleveldomain,(select username from users where users.id=domainnames.user_id) as username,registrationdate,validity,autorenew,(select code from status where status.id=domainnames.status_id) as status_code, (select description from status where status.id=domainnames.status_id) as status_name, (select baseprice from prices where prices.topleveldomain_id=domainnames.topleveldomain_id and prices.pricegroup_id=(select pricegroup_id from users where users.id=domainnames.user_id)) as costs from domainnames where domainnames.user_id=the_user_id and domainnames.domainname like '%'||domainsearchstring||'%' order by id limit pagesize offset ((pagenumber-1)*pagesize)
			loop
				foo.id := r.id;
				foo.domainname := r.domainname;
				foo.topleveldomain := r.topleveldomain;
				foo.username := r.username;
				foo.registrationdate := r.registrationdate;
				foo.validity := r.validity;
				foo.autorenew := r.autorenew;
				foo.status_code := r.status_code;
				foo.status_name := r.status_name;
				foo.costs := r.costs;
				return next foo;
			end loop;
			return;
		end if;
	end if;
end;
$$ language 'plpgsql';




--
-- my functions for DOMAINNAMES_USER
--

-- create a specific type here
create type domainname_user_type as (
	id integer,
	domainname varchar(255),
	topleveldomain varchar(10),
	registrationdate date,
	validity integer,
	autorenew boolean,
	status_code integer,
	status_name varchar(100),
	costs float
);

-- FUNCTION : returns the number of possible pages (used for paging) 
create function domainnames_user_get_pagecount(the_user_id integer) returns integer as $$
declare
	pagecount integer;
	pagesize integer default 5;
begin
	select count(id)/pagesize into pagecount from domainnames where user_id=the_user_id;
	if ((select count(id)%pagesize from domainnames where user_id=the_user_id)>0) then 
		pagecount := pagecount+1;
	end if;
	return pagecount;
end;
$$ language 'plpgsql';

-- FUNCTION : returns the results for a given "page"
create function domainnames_user_results(pagenumber integer, the_user_id integer) returns setof domainname_user_type as $$
declare
	r record;
	foo domainname_user_type;
	pagesize integer default 5;
begin
	for r in 
	  select id,domainname,(select domain from topleveldomains where topleveldomains.id=domainnames.topleveldomain_id) as topleveldomain,registrationdate,validity,autorenew,(select code from status where status.id=domainnames.status_id) as status_code, (select description from status where status.id=domainnames.status_id) as status_name, (select salesprice from prices where prices.topleveldomain_id=domainnames.topleveldomain_id and prices.pricegroup_id=(select pricegroup_id from users where users.id=domainnames.user_id)) as costs from domainnames where domainnames.user_id=the_user_id order by id limit pagesize offset ((pagenumber-1)*pagesize)
	loop
		foo.id := r.id;
		foo.domainname := r.domainname;
		foo.topleveldomain := r.topleveldomain;
		foo.registrationdate := r.registrationdate;
		foo.validity := r.validity;
		foo.autorenew := r.autorenew;
		foo.status_code := r.status_code;
		foo.status_name := r.status_name;
		foo.costs := r.costs;
		return next foo;
	end loop;
	return;
end;
$$ language 'plpgsql';


-- FUNCTION to get the domaincosts for all domains for a specific user
create function user_get_overall_domain_costs(the_user_id integer) returns float as $$
declare
	r record;
	temp_expense float default 0.0;
begin
		-- admin always has id = 1
		if (the_user_id=1) then
			for r in
			select id,(select baseprice from prices where prices.pricegroup_id=(select pricegroup_id from users where users.id=domainnames.user_id) and prices.topleveldomain_id=domainnames.topleveldomain_id) as expense from domainnames
			loop
				temp_expense := temp_expense + r.expense;
			end loop;
		else 
		-- user
			for r in
			select id,(select salesprice from prices where prices.pricegroup_id=(select pricegroup_id from users where users.id=the_user_id) and prices.topleveldomain_id=domainnames.topleveldomain_id) as expense from domainnames where domainnames.user_id=the_user_id
			loop
				temp_expense := temp_expense + r.expense;
			end loop;
		end if;
	return temp_expense;
end;
$$ language 'plpgsql';

--example: select * from user_get_overall_domain_costs(2);


-- FUNCTIONS to check if a domainname expires in one or two months

create type domain_expire_type as (
	id integer,
	domainname varchar(255),
	tld varchar(10),
	expire_date varchar(100),
	autorenew boolean
);

create function domain_expire_check(the_user_id integer, months_above integer) returns setof domain_expire_type as $$
declare
	foo domain_expire_type;
	r record;
	next_month integer;
begin
	-- variant one is to check for one months in advance
	if (months_above = 1) then
		select (extract(month from current_date)+1) into next_month;
		if (next_month = 13) then
			next_month := 1;
		end if;

		if (the_user_id = 1) then
			for r in 
				select id,domainname,autorenew,(registrationdate+((extract(year from current_date)-extract(year from registrationdate))*365)::integer) as expire_date, (select domain from topleveldomains where topleveldomains.id=domainnames.topleveldomain_id) as tld from domainnames where extract(month from registrationdate) = next_month and (extract(year from current_date)-extract(year from registrationdate))=domainnames.validity*(extract(year from current_date)-extract(year from registrationdate))
			loop
				foo.id := r.id;
				foo.domainname := r.domainname;
				foo.tld := r.tld;
				foo.expire_date := r.expire_date;
				foo.autorenew := r.autorenew;
				return next foo;
			end loop;
			return;
		else
			for r in 
				select id,domainname,autorenew,(registrationdate+((extract(year from current_date)-extract(year from registrationdate))*365)::integer) as expire_date, (select domain from topleveldomains where topleveldomains.id=domainnames.topleveldomain_id) as tld from domainnames where extract(month from registrationdate) = next_month and domainnames.user_id=the_user_id and (extract(year from current_date)-extract(year from registrationdate))=domainnames.validity*(extract(year from current_date)-extract(year from registrationdate))
			loop
				foo.id := r.id;
				foo.domainname := r.domainname;
				foo.tld := r.tld;
				foo.expire_date := r.expire_date;
				foo.autorenew := r.autorenew;
				return next foo;
			end loop;
			return;
		end if;
	end if;

	-- variant two is to check for two months in advance
	if (months_above = 2) then
		select (extract(month from current_date)+2) into next_month;
		if (next_month = 13) then
			next_month := 1;
		end if;

		if (next_month = 14) then
			next_month := 2;
		end if;

		if (the_user_id = 1) then
			for r in 
				select id,domainname,autorenew,(registrationdate+((extract(year from current_date)-extract(year from registrationdate))*365)::integer) as expire_date, (select domain from topleveldomains where topleveldomains.id=domainnames.topleveldomain_id) as tld from domainnames where extract(month from registrationdate) = next_month and (extract(year from current_date)-extract(year from registrationdate))=domainnames.validity*(extract(year from current_date)-extract(year from registrationdate))
			loop
				foo.id := r.id;
				foo.domainname := r.domainname;
				foo.tld := r.tld;
				foo.expire_date := r.expire_date;
				foo.autorenew := r.autorenew;
				return next foo;
			end loop;
			return;
		else
			for r in 
				select id,domainname,autorenew,(registrationdate+((extract(year from current_date)-extract(year from registrationdate))*365)::integer) as expire_date, (select domain from topleveldomains where topleveldomains.id=domainnames.topleveldomain_id) as tld from domainnames where extract(month from registrationdate) = next_month and domainnames.user_id=the_user_id and (extract(year from current_date)-extract(year from registrationdate))=domainnames.validity*(extract(year from current_date)-extract(year from registrationdate))
			loop
				foo.id := r.id;
				foo.domainname := r.domainname;
				foo.tld := r.tld;
				foo.expire_date := r.expire_date;
				foo.autorenew := r.autorenew;
				return next foo;
			end loop;
			return;
		end if;
	end if;
end;
$$ language 'plpgsql';

-- example: parm 1 is the user_id, parm2 is the amount of months to check in advance, 2 is maximum
-- select * from domain_expire_check(2,2);