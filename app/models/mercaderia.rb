class Mercaderia < ActiveRecord::Base
  extend Enumerize
  acts_as_paranoid
  after_create :generar_movimiento_stock
  belongs_to :categoria, -> { with_deleted }

  has_one :stock_balance, -> { order('anho DESC').order('mes DESC') }, class_name: 'MercaderiaPeriodoBalance'

  delegate :nombre, to: :categoria, prefix: true

  enumerize :unidad_de_medida, in: [:unidad, :metro, :litro, :kilo], predicates: true

  validates :nombre, presence: true, length: {maximum: 50, minimum: 2}
  validates :codigo, presence: true, length: {maximum: 20, minimum: 2}, uniqueness: true
  validates :categoria_id, presence: true
  validates :descripcion, length: {maximum: 150, minimum: 2}, allow_blank: true
  validates :unidad_de_medida, presence: true
  validates :precio_venta_contado, numericality: { greater_than_or_equal_to: 0 }
  validates :precio_venta_credito, numericality: { greater_than_or_equal_to: 0 }
  validates :stock_minimo,         numericality: { greater_than_or_equal_to: 0 }
  validates :stock_inicial, numericality: {less_than: DECIMAL_LIMITE[:superior] }

  default_scope { order('lower(nombre)') } # Ordenar por nombre por defecto
  scope :by_codigo, lambda { |value| where('lower(codigo) = ?', value.downcase) } # buscar por codigo

  def stock_actual
    stock_balance.nil? ? 0 : stock_balance.balance
  end

  def generar_movimiento_stock
    movimiento = MovimientoMercaderia.new(fecha: Date.today, motivo: "Stock inicial de nueva mercaderia", tipo: 'ingreso')
    movimiento.detalles.build(mercaderia_id: id, cantidad: stock_inicial)
    movimiento.save
  end

  def self.cantidad_total_de_existencias
    cantidad = 0
    Mercaderia.all.map{|m| cantidad += m.stock_actual}
    cantidad
  end

end
