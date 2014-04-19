require 'sinatra'
require 'data_mapper'
require 'haml'

DataMapper.setup(:default, ENV['DATABASE_URL'] || 'postgres://localhost/teledrink')

class Phone
  include DataMapper::Resource

  has n, :images

  property :number, Integer, key: true
end

class Image
  include DataMapper::Resource

  belongs_to :phone

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

post '/inbound_text' do
  phone = Phone.first_or_create number: params['From'].gsub(/[^\d]/, '').gsub(/\A1/, '')
  if params['NumMedia'].to_i > 0
    (0...params['NumMedia'].to_i).each do |num|
      image = Image.create url: params["MediaUrl#{num}"], phone: phone
    end
  end
  content_type 'text/xml'
  <<-xml
    <?xml version="1.0" encoding="UTF-8"?>
    <Response>
    </Response>
  xml
end

get '/:number' do |number|
  phone = Phone.first number: number
  haml :show, locals: { phone: phone }
end

get '/' do
  phones = Phone.all
  haml :index, locals: { phones: phones }
end
