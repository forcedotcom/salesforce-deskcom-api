# desk.com APIv2 [![Build Status](https://secure.travis-ci.org/tstachl/desk.png)](http://travis-ci.org/tstachl/desk) [![Coverage Status](https://coveralls.io/repos/tstachl/desk/badge.png)](https://coveralls.io/r/tstachl/desk) [![Dependency Status](https://gemnasium.com/tstachl/desk.png)](https://gemnasium.com/tstachl/desk)

desk.com has released v2 of their REST API a few months ago and provides a lot more functionality. You should read up on the current progress of the [API](http://dev.desk.com/API/changelog). This library wraps all of it into an easy to use ruby module. We'll try to keep up with the changes of the API but things might still break unexpectedly.

## Installation

```ruby
gem install desk_api
```

## Example
This example shows you how to create a new client and establish a connection to the API. It shows the four request methods supported by the desk.com API (`GET`, `POST`, `PATCH` and `DELETE`).

```ruby
# Basic Auth
client = Desk::Client.new username: 'thomas@example.com', password: 'somepassword', subdomain: 'devel'
# OAuth
client = Desk::Client.new({
  token: 'TOKEN',
  token_secret: 'TOKEN_SECRET',
  consumer_key: 'CONSUMER_KEY',
  consumer_secret: 'CONSUMER_SECRET',
  subdomain: 'devel'
})

response = client.get '/api/v2/topics'
response = client.post '/api/v2/topics', name: 'My new Topic', allow_questions: true
response = client.patch '/api/v2/topics/1', name: 'Changed the Topic Name'
response = client.delete '/api/v2/topics/1' 
```

For ease of use and if you only create one connection to the desk.com API you can use `Desk` directly:

```ruby
Desk.configure do |config|
  config.username = 'thomas@example.com'
  config.password = 'somepassword'
  config.subdomain = 'devel'
end

Desk.get '/api/v2/topics'
Desk.post '/api/v2/topics', name: 'My new Topic', allow_questions: true
Desk.patch '/api/v2/topics/1', name: 'Changed the Topic Name'
Desk.delete '/api/v2/topics/1'
```

## Working with Resources and Collections

The API supports RESTful resources and so does this wrapper. Those resources are automatically discovered, meaning you can navigate around without having to worry about anything. We also support two finder methods `by_url` and `by_id`, the former works with any resource, the latter needs a collection.

### Finders
```ruby
# get the first user and find a case by url.
found_case = Desk.users.first.by_url '/api/v2/cases/1'

# find a case by case number
found_case = Desk.cases.by_id 1
```

### Pagination

As mentioned above you can also navigate between resources and mainly pages of collections.

```ruby
cases = Desk.cases
cases.each do |my_case|
  # do something with the case
end
# now move on to the next page
next_page = cases.next_page
next_page.each do |my_case|
  # do something with the case
end
# go back to the previous page
previous_page = next_page.previous_page
# or go to the last page
last_page = previous_page.last_page
# or go to the first page
first_page = last_page.first_page
```

### Links

Pagination is pretty obvious but the cool part about pagination or rather resources is the auto-linking. As soon as the resource has a link defined, it'll be navigatable:

```ruby
# get the customer of the first case of the first page
customer = Desk.cases.first.customer
# who sent the first outbound reply of the first email
user_name = Desk.cases.select{ |my_case| 
              my_case.type == 'email'
            }.first.replies.select{ |reply|
              reply.direction == 'out'
            }.first.sent_by.name
```

### Lazy loading

Collections and resources in general are lazily loaded, meaning if you request the cases `Desk.cases` no actual request will be set off until you actually request data. This makes sure only necessary requests are fired and which keeps the overall requests low and spares the [desk.com rate limit](http://dev.desk.com/API/using-the-api/#rate-limits).

```ruby
Desk.cases.page(10).per_page(50).each do |my_case|
  # in this method chain `.each' is the first method that acutally sends a request
end

# however if you request the current page numer and the resource is not loaded
# it'll send a request
Desk.cases.page == 1
```

### Create, Update and Delete

Of course we support creating, updating and deleting resources but not all resources can be deleted or updated or created, if that's the case for the resource you're trying to update, it'll throw a `Desk::Error::MethodNotSupported` error. The specific method won't be defined on the resource either `Desk.cases.first.respond_to?(:delete) == false`.

```ruby
# let's create an article
new_article = Desk.articles.create({
                subject: 'Some Subject',
                body: 'Some Body',
                _links: {
                  topic: Desk.topics.first.get_self
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
  Desk.cases.first.delete
rescue Desk::Error::MethodNotSupported => e
  # too bad
end
```

### Getters & Setters

As you have seen in prior examples for each field on the resource we create a getter and setter. Be careful if a resource is not updatable it won't have a setter specified.

```ruby
customer = Desk.customers.by_id(1)

puts customer.first_name
puts customer.last_name
puts customer.title

# for updates you can either use the setter or a hash

customer.first_name = 'John'
customer.last_name = 'Doe'

updated_customer = customer.update title: 'Master of the Universe'

# users are not updatable
begin
  user = Desk.users.first
  user.name = 'Not updateable'
rescue Desk::Error::MethodNotSupported
  # too bad
end
```

### API Errors

Sometimes the API is going to return errors, eg. Validation Error. In these cases we wrap the API error into a `Desk::Error`. Here are the common errors:

```ruby
Desk::Error::BadRequest             #=> 400 Status
Desk::Error::Unauthorized           #=> 401 Status
Desk::Error::Forbidden              #=> 403 Status
Desk::Error::NotFound               #=> 404 Status
Desk::Error::MethodNotAllowed       #=> 405 Status
Desk::Error::NotAcceptable          #=> 406 Status
Desk::Error::Conflict               #=> 409 Status
Desk::Error::UnsupportedMediaType   #=> 415 Status
Desk::Error::UnprocessableEntity    #=> 422 Status
Desk::Error::TooManyRequests        #=> 429 Status
```

Please also have a look at all [desk.com API errors](http://dev.desk.com/API/using-the-api/#status-codes) and their respective meanings.

## License

(The MIT License)

Copyright (c) 2013 Thomas Stachl &lt;tom@desk.com&gt;

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the 'Software'), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.