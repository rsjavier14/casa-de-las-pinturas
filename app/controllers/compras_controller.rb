class ComprasController < ApplicationController
  layout 'imprimir', only: [:imprimir, :imprimir_show]
  before_action :set_compra, only: [:show, :imprimir_show, :edit, :update, :destroy]
  before_action :setup_menu, only: [:index, :new, :edit, :show, :create, :update]

  # configuracion del menu
  def setup_menu
    @menu_setup[:main_menu] = :compras
    @menu_setup[:side_menu] = :compras_sidemenu
  end

  def buscar_devoluciones
    @proveedor = Proveedor.find(params[:persona_id])

    @devoluciones = @proveedor.devoluciones_disponibles
  end

  def imprimir
    get_compras
  end

  def imprimir_show
  end

  # GET /compras
  # GET /compras.json
  def index
    get_compras
  end

  # GET /compras/1
  # GET /compras/1.json
  def show
    @stock_negativo = @compra.check_detalles_negativos(true)
  end

  # GET /compras/new
  def new
    @compra = Compra.new
    @compra.detalles.build

    get_pago

    render :form
  end

  # GET /compras/1/edit
  def edit
    @pago.rebuild_detalles if @pago
    render :form
  end

  # POST /compras
  # POST /compras.json
  def create
    nueva_compra
    respond_to do |format|
      Compra.transaction do
        if @compra.guardar(compra_params, params[:guardar_si_o_si].present?)
          format.html { redirect_to @compra, notice: t('mensajes.save_success', recurso: 'la compra') }
          format.json { render :show, status: :created, location: @compra }
        else
          get_pago
          format.html { render :form }
          format.json { render json: @compra.errors, status: :unprocessable_entity }
        end
      end
    end

  end

  def nueva_compra
    @compra = Compra.new
  end

  # PATCH/PUT /compras/1
  # PATCH/PUT /compras/1.json
  def update
    respond_to do |format|
      Compra.transaction do
        if @compra.guardar(compra_params, params[:guardar_si_o_si].present?)
          format.html { redirect_to @compra, notice: t('mensajes.save_success', recurso: 'la compra') }
          format.json { render :show, status: :created, location: @compra }
        else
          @pago = @compra.recibos_detalles.first.recibo if @compra.recibos_detalles.first
          @pago.rebuild_detalles if @pago
          format.html { render :form }
          format.json { render json: @compra.errors, status: :unprocessable_entity }
        end
      end
    end

  end

  # DELETE /compra/1
  # DELETE /compra/1.json
  def destroy
    respond_to do |format|
      Compra.transaction do
        if @compra.destroy
          format.html { redirect_to compras_url, notice: t('mensajes.delete_success', recurso: 'la compra') }
          format.json { head :no_content }
        else
          flash[:error] = t('mensajes.delete_error', recurso: 'la compra', errores: @compra.errors.full_messages.to_sentence)
          format.html { redirect_to @compra }
        end
      end
    end
  end

  private

    def get_compras
      procesar_fechas
      @search = Compra.search(params[:q])
      @compras = @search.result.includes(:persona, :detalles).page(params[:page]).per(action_name == 'imprimir' ? LIMITE_REGISTROS_IMPRIMIR : 25)
    end

    # Use callbacks to share common setup or constraints between actions.
    def set_compra
      @compra = Compra.find(params[:id])
      @pago = @compra.recibos.first
    end

    def get_pago
      if @compra.recibos_detalles.first
        @pago = @compra.recibos_detalles.first.recibo
        @pago.rebuild_detalles if @pago
      else
        @recibo_detalle = @compra.recibos_detalles.build
        @pago = @recibo_detalle.build_recibo
        @pago.build_detalles
      end
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def compra_params
      procesar_cantidades_mercaderias
      procesar_cantidades_pagos
      procesar_devoluciones(params[:compra][:condicion])

      params[:compra].delete("recibos_detalles_attributes") if params[:compra][:condicion] == "credito"
      params.require(:compra).permit(:persona_id, :numero_comprobante, :fecha, :fecha_vencimiento, :estado, :condicion,
                                     recibos_detalles_attributes:[:id, :_destroy,
                                       recibo_attributes:  [:id, :fecha, :persona_id, :_destroy,
                                         detalles_attributes: [:id, :monto, :cotizacion, :moneda_id, :forma, :_destroy]
                                       ]
                                     ],
                                     creditos_detalles_attributes: [:id, :notas_creditos_debito_id, :monto_utilizado, :_destroy],
                                     detalles_attributes: [:id, :mercaderia_id, :cantidad, :precio_unitario, :_destroy],
                                     )
    end

    # Setear las fechas "hasta" para que incluya el dia entero
    # 01/03/2016 => 2016-03-01 23:59:59
    def procesar_fechas
      if params[:q].present? && params[:q][:fecha_lt].present?
        params[:q][:fecha_lt] = params[:q][:fecha_lt].to_datetime.end_of_day
      end
    end

    def procesar_cantidades_mercaderias
      params[:compra][:detalles_attributes].each do |i, d|
        params[:compra][:detalles_attributes][i][:cantidad] = cantidad_a_numero(d[:cantidad])
        params[:compra][:detalles_attributes][i][:precio_unitario] = cantidad_a_numero(d[:precio_unitario])
      end
    end

    def procesar_cantidades_pagos
      if params[:compra][:recibos_detalles_attributes]
        pago = params[:compra][:recibos_detalles_attributes]["0"][:recibo_attributes]
        pago[:detalles_attributes].each do |i, d|
          pago[:detalles_attributes][i][:_destroy] = '1' if cantidad_a_numero(d[:monto]) == 0 # marcar para eliminar si el monto es cero
          pago[:detalles_attributes][i][:monto] = cantidad_a_numero(d[:monto])
          pago[:detalles_attributes][i][:cotizacion] = cantidad_a_numero(d[:cotizacion])
        end
      end
    end

    def procesar_devoluciones(condicion)

      if condicion == 'contado' && !params[:compra][:creditos_detalles_attributes].blank?

        params[:compra][:creditos_detalles_attributes].each do |k, valor|

          params[:compra][:creditos_detalles_attributes][k][:monto_utilizado] = cantidad_a_numero(valor[:monto_utilizado])

          # se eliminan de params las boletas que no se seleccionaron o se marcan para eliminar
          if valor[:id].present?
            params[:compra][:creditos_detalles_attributes][k][:_destroy] = '1' unless valor[:usado].present?
          else
            params[:compra][:creditos_detalles_attributes].delete(k) unless valor[:usado].present?
          end
        end

      else
        params[:compra].delete("creditos_detalles_attributes")
      end

    end

end
