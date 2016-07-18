#create table template
rails generate scaffold ENTITY PROPERTY1:TYPE1 PROPERTY2:TYPE2 
#example
rails generate scaffold Evento nome:string local:string inicio:datetime termino:datetime

#create table
rake db:migrate
