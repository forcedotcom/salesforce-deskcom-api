# DeskApi a client for APIv2

[![Build Status](https://secure.travis-ci.org/tstachl/desk_api.png)](http://travis-ci.org/tstachl/desk_api)
[![Coverage Status](https://coveralls.io/repos/tstachl/desk_api/badge.png?branch=develop)](https://coveralls.io/r/tstachl/desk_api?branch=develop)
[![Dependency Status](https://gemnasium.com/tstachl/desk_api.png)](https://gemnasium.com/tstachl/desk_api)

___
## An Awesomely Unofficial Desk API Client
___

DeskApi takes the capabilities of the Desk.com API and wraps them up in a Ruby
client so that it's easy-as-pie to get working with your support site's API.

Desk publishes a changelog monthly, which you can keep up with at
[dev.desk.com/API/changelog](http://dev.desk.com/API/changelog).

We do our best to keep DeskApi, but please
don't hesitate to open an [issue](https://github.com/tstachl/desk/issues) or send a [pull request](https://github.com/tstachl/desk/pulls) if you find a bug or would like to new functionality added.


___
## Getting Started
___

### Installation
Easy!

```ruby
gem install desk_api
```
___
### Configuration

There are two different ways to configure DeskApi to send and receive requests:

#### First Configuration Option

Configure `DeskApi` itself to send/receive requests by calling the `configure` 
method to set up your authentication credentials:

```ruby
DeskApi.configure do |config|
  # basic authentication
  config.username = 'thomas@example.com'
  config.password = 'somepassword'

  # oauth configuration
  config.token           = 'TOKEN'
  config.token_secret    = 'TOKEN_SECRET'
  config.consumer_key    = 'CONSUMER_KEY'
  config.consumer_secret = 'CONSUMER_SECRET'

  config.endpoint = 'https://devel.desk.com'
end

DeskApi.get '/api/v2/topics'
DeskApi.post '/api/v2/topics', name: 'My new Topic', allow_questions: true
DeskApi.patch '/api/v2/topics/1', name: 'Changed the Topic Name'
DeskApi.delete '/api/v2/topics/1'
```

#### Second Configuration Option

Initialize a new `DeskApi::Client` to send/receive requests

This example shows you how to initialize a new client and the four main request
methods supported by the Desk.com API (`GET`, `POST`, `PATCH` and `DELETE`).

```ruby
# basic authentication
client = DeskApi::Client.new username: 'thomas@example.com', password: 'somepassword', endpoint: 'https://devel.desk.com'
# oauth configuration
client = DeskApi::Client.new({
  token: 'TOKEN',
  token_secret: 'TOKEN_SECRET',
  consumer_key: 'CONSUMER_KEY',
  consumer_secret: 'CONSUMER_SECRET',
  endpoint: 'https://devel.desk.com'
})

response = client.get '/api/v2/topics'
response = client.post '/api/v2/topics', name: 'My new Topic', allow_questions: true
response = client.patch '/api/v2/topics/1', name: 'Changed the Topic Name'
response = client.delete '/api/v2/topics/1'
```


___
## Resources
___

Resources are automatically discovered by the DeskApi. When requesting a
resource from DeskAPI, the client sends the request and returns a
`DeskApi::Resource`. If the client receives an error back from the API a
`DeskApi::Error` is raised.

___
### Create Read Update Delete

One of the most important features; we support creating, updating and deleting
resources but not all resources can be deleted or updated or created, if that's
the case for the resource you're trying to update, it'll throw a
`DeskApi::Error::MethodNotAllowed` error. For ease of use and because we wanted
to build as less business logic into the wrapper as possible, all of the methods
are defined on each `DeskApi::Resource` and will be sent to desk.com. However
the API might respond with an error if you do things that aren't supported.

```ruby
# let's create an article
new_article = DeskApi.articles.create({
                subject: 'Some Subject',
                body: 'Some Body',
                _links: {
                  topic: DeskApi.topics.first.get_self
                }
              })

# as you can see here a `Resource' always includes a method `.get_self'
# which will return the link object to build relationships

# updating the article
updated_article = new_article.update subject: 'Updated Subject'

# deleting the article
if updated_article.delete == true
  # article has been deleted
end

# ATTENTION: Cases can not be deleted!
begin
  DeskApi.cases.first.delete
rescue DeskApi::Error::MethodNotAllowed => e
  # too bad
end
```
___
### Getters & Setters

As you have seen in prior examples for each field on the resource we create a
getter and setter.

```ruby
customer = DeskApi.customers.find(1)

puts customer.first_name
puts customer.last_name
puts customer.title

# for updates you can either use the setter or a hash

customer.first_name = 'John'
customer.last_name = 'Doe'

updated_customer = customer.update title: 'Master of the Universe'

# users are not updatable
begin
  user = DeskApi.users.first
  user.update name: 'Not updateable'
rescue DeskApi::Error::MethodNotAllowed
  # too bad
end
```
___
### Find

The method `by_url` can be called on the client, for backwards compatability we
haven't yet removed it from the `DeskApi::Resource` but it will be removed once
we release v1 of this client. `by_url` will return a lazy loaded instance of the
resource.

```ruby
first_reply = DeskApi.by_url '/api/v2/cases/1/replies/1'
```

Since the update to v0.5 of the API wrapper the `find` method can now be called
on all `DeskApi::Resource` instances. _Gotcha:_ It will rebuild the base path
based on the resource/collection it is called on. So if you call it on the cases
collection `DeskApi.cases.find 1` the path will look like this:
`/api/v2/cases/:id`.

| Method                                                      | Path                        |
| ----------------------------------------------------------- | --------------------------- |
| `DeskApi.cases.find(1)`                                     | `/api/v2/cases/1`           |
| `DeskApi.cases.entries.find(1)`                             | `/api/v2/cases/1`           |
| `DeskApi.cases.search(subject: 'Test').find(1)`             | `/api/v2/cases/1`           |
| `DeskApi.cases.search(subject: 'Test').entries.find(1)`     | `/api/v2/cases/1`           |
| `DeskApi.cases.entries.first.replies.find(1)`               | `/api/v2/cases/1/replies/1` |
| `DeskApi.cases.entries.first.replies.entries.first.find(1)` | `/api/v2/cases/1/replies/1` |
___
### Pagination

As mentioned above you can also navigate between resources and pages of
collections.

```ruby
cases = DeskApi.cases
cases.entries.each do |my_case|
  # do something with the case
end

# now move on to the next page
next_page = cases.next
next_page.entries.each do |my_case|
  # do something with the case
end

# go back to the previous page
previous_page = next_page.previous

# or go to the last page
last_page = previous_page.last

# or go to the first page
first_page = last_page.first
```
___
### `all` and `each_page`

As a recent addition we made it even easier to navigate through all the pages.

```ruby
DeskApi.cases.all do |current_case, current_page_number|
  # do something with the case
end

DeskApi.cases.each_page do |current_page, current_page_number|
  # do something with the current page
end
```

Both methods use the max `per_page` for the API endpoint for that particular
resource.
___
### List params

Some lists allow for additional params like [cases](http://dev.desk.com/API/cases/#list).
This allows you to filter the cases endpoint by using a `company_id`,
`customer_id` or `filter_id` list param.

```ruby
# fetch cases for the company with id 1
companys_cases = DeskApi.cases(company_id: 1)

# fetch cases for the customer with id 1
customers_cases = DeskApi.cases(customer_id: 1)

# fetch cases for the filter with id 1
filters_cases = DeskApi.cases(filter_id: 1)
```
___
### Sorting

There is a maximum `page` limit on some Desk.com API endpoints. As of right now
(May 2014) the limit is 500 for all endpoints that are limited, but please
consult the #list documentation for each resource:

- [Case list](http://dev.desk.com/API/cases#list)
- [Company Case list](http://dev.desk.com/API/companies#cases-list)
- [Customer Case list](http://dev.desk.com/API/customers#cases-list)
- [Filter Case list](http://dev.desk.com/API/filters#list-cases)
- [Case search](http://dev.desk.com/API/cases#search)
- [Customer search](http://dev.desk.com/API/customers#search)
- [Company search](http://dev.desk.com/API/companies#search)
- [Article search](http://dev.desk.com/API/articles#search)


To work around page limits, you can specify `sort_field` and `sort_direction`

```ruby
# fetch cases sorted by updated_at direction desc
sorted_cases = DeskApi.cases(sort_field: :updated_at, sort_direction: :desc)
```
___
### Links

Once a `DeskApi::Resource` has loaded, its [linked resources](http://dev.desk.com/API/using-the-api/#relationships) can be retrieved
by calling the linked resource as a method of the `DeskApi::Resource`, e.g., 

```ruby
# Get a ticket
ticket = DeskApi.cases.entries.first

# Get the ticket's assigned_user from the ticket
assigned_user = ticket.assigned_user

# Get the customer from the ticket
customer = ticket.customer

# Get the customer's company from the customer.
company = customer.company

# Getting the name of the user who sent the first outbound reply on a ticket
user_name = DeskApi.
              cases.
              entries.
              select { |my_case| my_case.type == 'email' }.
              first.
              replies.
              entries.select { |reply| reply.direction == 'out' }.
              first.
              sent_by.
              name
```
___
### Lazy loading

Resources are lazy loaded. This means that requests are only sent when you
request data from the resource. This helps a lot with flying under the Desk.com
API [rate limit](http://dev.desk.com/API/using-the-api/#rate-limits). E.g.,

```ruby
DeskApi.cases.page(10).per_page(50).entries.each do |my_case|
  # in this method chain, no HTTP request is fired until `.entries'
end

# however if you request the current page numer and the resource is not loaded
# it'll send a request
DeskApi.cases.page == 1
```
___
### Embedding

Some endpoints support [embedding](http://dev.desk.com/API/using-the-api/#embedding) related resources. E.g., when getting a list
of cases from `/api/v2/cases` you can embed the customer on each case by adding
`embed=` to the query string: `/api/v2/cases?embed=customer`

The client supports this: `tickets_and_customers = DeskApi.cases.embed(:customer)`

Taking advantage of `.embed` is a great way to be conscious of the rate limit
and minimize necessary HTTP requests.


**Not using embedded resources**
```ruby
tickets = DeskApi.cases.per_page(100).entries # HTTP request
tickets.each do |ticket|
  puts ticket.customer.first_name # HTTP request (100 iterations)
end

# Total Requests: 101
```

**Using embedded resources**
```ruby
tickets = DeskApi.cases.per_page(100).embed(:customer).entries # HTTP request
tickets.each do |ticket|
  puts ticket.customer.first_name # No HTTP Request, customer is embedded
end

# Total Requests: 1
```

**Using embedded resources in `find`**
```ruby
my_case = DeskApi.cases.find(1, embed: :customer)
# OR
my_case = DeskApi.cases.find(1, embed: [:customer, :assigned_user, :assigned_group, :message])

customer = my_case.customer
assigned_user = my_case.assigned_user
assigned_group = my_case.assigned_group
```
___
### API Errors

Sometimes the API is going to return errors, eg. Validation Error. In these
cases we wrap the API error into a `DeskApi::Error`. Here are the common errors:

```ruby
DeskApi::Error::BadRequest             #=> 400 Status
DeskApi::Error::Unauthorized           #=> 401 Status
DeskApi::Error::Forbidden              #=> 403 Status
DeskApi::Error::NotFound               #=> 404 Status
DeskApi::Error::MethodNotAllowed       #=> 405 Status
DeskApi::Error::NotAcceptable          #=> 406 Status
DeskApi::Error::Conflict               #=> 409 Status
DeskApi::Error::UnsupportedMediaType   #=> 415 Status
DeskApi::Error::UnprocessableEntity    #=> 422 Status
DeskApi::Error::TooManyRequests        #=> 429 Status
```

Please also have a look at all
[desk.com API errors](http://dev.desk.com/API/using-the-api/#status-codes) and
their respective meanings.

___
## License
___

(The MIT License)

Copyright (c) 2013-2014 Thomas Stachl <tstachl@salesforce.com>

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the 'Software'), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
