require 'sinatra'
require 'data_mapper'
require 'haml'
require 'json'

DataMapper.setup(:default, ENV['DATABASE_URL'] || 'postgres://localhost/teledrink')

class Email
  include DataMapper::Resource

  has n, :images

  property :address, String, key: true
end

class Image
  include DataMapper::Resource

  belongs_to :email

  property :id, Serial
  property :url, Text
  property :created_at, DateTime
end

DataMapper.finalize
DataMapper.auto_upgrade!

if settings.production?
  use Rack::Auth::Basic, "Teledrink" do |username, password|
    username == 'gin' and password == 'tonic'
  end
end

post '/inbound_email' do
  email = Email.first_or_create(address: params['Sender'])
  attachments = JSON.parse(params['attachments'])
  attachments.each do |attachment|
    image = Image.create url: attachment['url'], email: email
  end
  200
end

get /(.+)/ do |address|
  if email = Email.first(address: address)
    haml :show, locals: { email: email }
  else
    404
  end
end

get '/' do
  emails = Email.all
  haml :index, locals: { emails: emails }
end
