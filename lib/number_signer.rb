require 'digest'
module NumberSigner
  def self.sign(number)
    Digest::SHA2.hexdigest(ENV['NUMBER_SALT'] + number)
  end
end
