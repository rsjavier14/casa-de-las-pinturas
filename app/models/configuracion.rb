class Configuracion < ActiveRecord::Base
	require 'carrierwave/orm/activerecord'
	mount_uploader :avatar, CloudinaryUploader # Para heroku
	# mount_uploader :avatar, AvatarUploader # Para usar localmente en produccion

	validates :empresa_nombre, presence: true, length: {maximum: 50, minimum: 2}
	validates :empresa_direccion, presence: true, length: {maximum: 150, minimum: 2}
	validates :empresa_telefono, length: {maximum: 50}
	validates :empresa_email, format: { with: /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i, message: :email_invalido}, length: {maximum: 150, minimum: 2}
	validate :validacion_tamanho_logo

  def validacion_tamanho_logo
    errors[:avatar] << "El logo no puede ser mayor a 1 MB" if avatar.size > 1.megabytes
  end
end

