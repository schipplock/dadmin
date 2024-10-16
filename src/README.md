# DAdmin - Domain Administration

## Short Description

DAdmin is a web application written in Perl to manage customers, 
domainnames, prices, pricegroups, topleveldomains, expirations, 
renewals, costs and so on. This web application is intended to be 
used by internet service providers who offer domain services to 
their customers and who need a way to manage their customers, 
their domainnames they registered/ordered and the prices 
associated to them.

DAdmin is a tool for service providers and its customers.

![DAdmin](https://raw.githubusercontent.com/schipplock/dadmin/master/screenshots/adminscreen.png)

## Technology Involved

DAdmin is based on Perl. It’s powered by mod_perl and uses 
the object-relational database management system Postgresql. 
For this project I made heavy use of self defined server side 
functions in PL/pgSQL to ease many aspects of getting the 
appropriate data. For example getting all domainnames that 
expire this and next month requires quite some joins or at 
least some nested subselects which is the downside of 
normalisation but having the serverside functions I could 
encapsulate all the selects and form an appropriate result 
set which then again can be used by my perl script to display 
the data e.g. Having all these select statements which I also 
had to repeat in my perl scripts would lead to unmaintainable 
code or at least less maintainable code. This way I simply call 
a serverside function and get my result set. However, I 
managed to get a new friend called Moose which is the post 
modern object system for perl and it helped me a lot to get 
a modular system which is scalable, very easy 
to maintain and very hard to misunderstand. Using Moose I could
architect a code base that is easy to reason about.

## What Is This Project For?

The idea of the project wasn’t just because I felt boring or 
mouldy. I had this project in mind many years ago when I 
started at TeKoNet GmbH in Essen. We, as in 
the company, offer domain services to our customers and the 
process to bill a domain name was quite fancy; imagine a 
customer that calls me and asks for a domain name to register;
I tell the customer to send me an email with the desired domain 
name and I will then register it for him. I then have to tell my 
boss that customer X has ordered a domain name and that 
we have to bill him.

The whole process was time consuming and prone to mistakes.

So the motivation for DAdmin was born. The name DAdmin 
simply means “domain admin”. However, I planned a web 
application that could manage the costs, the domain names, 
the customers etc...the result is DAdmin. Now also customers 
have an overview of their domain names and costs because 
they also now have a system to get in touch with us.

And DAdmin itself simply sends out reports which domain 
names are to be expired or renewed next and the month 
after so we can simply bill the customers.

That's it.
