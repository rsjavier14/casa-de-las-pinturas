var PagosUI = (function(){
    var elementos = null,
        buscarProveedorUrl = '',
        boletasPendientesUrl = '';

    function noHayPendientes(proveedor){
        elementos.mensajePanel.find('h3').text('No hay boletas pendientes para el proveedor ' + proveedor);
        elementos.mensajePanel.find('i').removeClass('fa-search').addClass('fa-list');
    }

    function seleccioneProveedor(){
        elementos.mensajePanel.find('h3').text('Seleccione un proveedor para ver las boletas y devoluciones pendientes');
        elementos.mensajePanel.find('i').removeClass('fa-list').addClass('fa-search');
        elementos.mensajePanel.removeClass('hide');
        elementos.boletasPanel.addClass('hide');
        elementos.detallesPanel.addClass('hide');
    }

    function mostrarBoletas() {
        elementos.mensajePanel.addClass('hide');
        elementos.boletasPanel.removeClass('hide');
        elementos.detallesPanel.removeClass('hide');
        NumberHelper.mascaraMoneda('.mascaraMoneda');
    }

    function initFormEvents(){

        PersonasUI.buscador({elemento: elementos.proveedorBuscador, url: buscarProveedorUrl});

        elementos.pagosForm.validate({ignore: []}); // validar formulario. ignore: [] es para que valide campos no visibles tambien

        NumberHelper.mascaraMoneda('.maskMoneda');

        DatepickerHelper.initDatepicker('.datepicker');

        // Abrir el buscador de proveedores cuando se hace click en el panel inicial
        elementos.pagosForm.on('click', '.seleccionar-panel', function(e){
            elementos.proveedorBuscador.select2('open');
        });

        // Buscar boletas y devoluciones pendientes del proveedor
        elementos.proveedorBuscador.on('change', function(e){
            if($(this).val() === ''){
                seleccioneProveedor();
                return false;
            }

            $.ajax(boletasPendientesUrl + '?proveedor_id=' + $(this).val(), {
                dataType: 'script',
                beforeSend: function(){
                    console.log('ddd');
                }
            })
        });

        TablasHelper.calcularSeleccionados('#compra-detalles-tabla');

    }

    return {
        init: function() {
            elementos = {
                pagosForm: $('#pago-form'),
                proveedorBuscador: $('#proveedores-buscador'),
                mensajePanel: $('#pago-mensajes'),
                boletasPanel: $('#pago-boletas-devoluciones'),
                detallesPanel: $('#pago-detalles')

            }
        },
        index: function() {
            DatepickerHelper.initDateRangePicker('#date-range');
            PersonasUI.buscador({elemento: elementos.proveedorBuscador, url: buscarProveedorUrl});
        },
        'new': function() {
            initFormEvents();
        },
        'create': function(){
            initFormEvents();
        },
        'edit': function() {
            initFormEvents();
        },
        'update': function(){
            initFormEvents();
        },
        noHayPendientes: noHayPendientes,
        mostrarBoletas: mostrarBoletas,
        setbuscarProveedorUrl: function(url) {
            buscarProveedorUrl = url;
        },
        setboletasPendientesUrl: function(url) {
            boletasPendientesUrl = url;
        }

    };

}());
