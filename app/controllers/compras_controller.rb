class ComprasController < ApplicationController
  layout 'imprimir', only: [:imprimir]
  before_action :set_compra, only: [:show, :edit, :update, :destroy]
  before_action :setup_menu, only: [:index, :new, :edit, :show, :create, :update]

  # configuracion del menu
  def setup_menu
    @menu_setup[:main_menu] = :compras
    @menu_setup[:side_menu] = :compras_sidemenu
  end

  def imprimir
    get_compras
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
    render :form
  end

  # GET /compras/1/edit
  def edit
    render :form
  end

  # POST /compras
  # POST /compras.json
  def create
    #binding.pry
    @compra = Compra.new(compra_params)

    respond_to do |format|
      Compra.transaction do
        if @compra.save
          format.html { redirect_to @compra, notice: t('mensajes.save_success', recurso: 'la compra') }
          format.json { render :show, status: :created, location: @compra }
        else
          format.html { render :form }
          format.json { render json: @compra.errors, status: :unprocessable_entity }
        end
      end
    end

  end

  # PATCH/PUT /compras/1
  # PATCH/PUT /compras/1.json
  def update
    @compra.assign_attributes(compra_params)
    @stock_negativo = params[:guardar_si_o_si].present? ? [] : @compra.check_detalles_negativos
    respond_to do |format|
      Compra.transaction do
        if @stock_negativo.size <= 0 && @compra.save
          format.html { redirect_to @compra, notice: t('mensajes.save_success', recurso: 'la compra') }
          format.json { render :show, status: :created, location: @compra }
        else
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
      @search = Compra.search(params[:q])
      @compras = @search.result.includes(:persona, :detalles).page(params[:page]).per(action_name == 'imprimir' ? LIMITE_REGISTROS_IMPRIMIR : 25)
    end
    # Use callbacks to share common setup or constraints between actions.
    def set_compra
      @compra = Compra.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def compra_params
      procesar_cantidades
      params.require(:compra).permit(:persona_id, :numero_comprobante, :fecha, :fecha_vencimiento, :estado, :condicion,
                                     detalles_attributes: [:id, :mercaderia_id, :cantidad, :precio_unitario, :_destroy])
    end

    def procesar_cantidades
      params[:compra][:detalles_attributes].each do |i, d|
        params[:compra][:detalles_attributes][i][:cantidad] = cantidad_a_numero(d[:cantidad])
        params[:compra][:detalles_attributes][i][:precio_unitario] = cantidad_a_numero(d[:precio_unitario])
      end
    end

end