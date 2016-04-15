module MovimientosHelper

  # Formatea los movimientos para mostrarlo en la vista
  # recibe un listado de Movimientos de Extractos
  # retorna un arreglo de hashes
  # [{url: url para acceder al movimiento,
  #   fecha: fecha del movimiento,
  #   motivo: el motivo del movimiento(compra, venta, movimiento, etc),
  #   ingreso: ingreso que corresponda,
  #   egreso: egreso que corresponda}, {}, ...]
  def formatear_movimientos(movimientos)

    resultado = []

    movimientos.each do |m|
      # Por cada tipo de movimiento se configura de manera adecuada el hash

      # Aca va cada movimiento
      case m.movimiento_tipo
        # -------------------------------
        # MOVIMIENTOS DE MERCADERIAS
        # -------------------------------
        when 'MovimientoMercaderiaDetalle'
          detalle = m.movimiento_mercaderia_detalle
          es_ingreso = detalle.movimiento_mercaderia.tipo.ingreso?
          resultado << {url: "/movimiento_mercaderia/#{detalle.movimiento_mercaderia.id}",
                        fecha: detalle.movimiento_mercaderia.fecha,
                        motivo: detalle.movimiento_mercaderia.motivo,
                        ingreso: es_ingreso ? detalle.cantidad : 0,
                        egreso: es_ingreso ? 0 : detalle.cantidad}
        # -------------------------------
        # MOVIMIENTOS DE CUENTAS CORRIENTES - CLIENTES / PROVEEDORES
        # -------------------------------
        when 'Recibo'
          recibo = m.recibo
          es_ingreso = recibo.instance_of?(Pago)
          resultado << {url: "/#{es_ingreso ? 'pagos' : 'cobros'}/#{recibo.id}",
                        fecha: recibo.fecha,
                        motivo: recibo.movimiento_motivo,
                        ingreso: es_ingreso ? recibo.importe_pagado : 0,
                        egreso: es_ingreso ? 0 : recibo.importe_pagado}
        # -------------------------------
        # MOVIMIENTOS DE CAJA
        # -------------------------------
        when 'ReciboDetalle'
          detalle = m.recibo_detalle
          es_ingreso = !detalle.recibo.instance_of?(Pago)
          resultado << {url: "/#{es_ingreso ? 'cobros' : 'pagos'}/#{detalle.recibo_id}",
                        fecha: detalle.recibo.fecha,
                        motivo: detalle.recibo.movimiento_motivo,
                        ingreso: es_ingreso ? detalle.monto : 0,
                        egreso: es_ingreso ? 0 : detalle.monto}
        else
          logger.info "No existe el tipo #{m.movimiento_tipo}"
      end
    end

    resultado
  end

end