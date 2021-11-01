import 'package:flutter/material.dart';
import 'package:from_zero_ui/from_zero_ui.dart';
import 'package:from_zero_ui/src/field_bool.dart';
import 'package:from_zero_ui/src/field_string.dart';
import 'package:from_zero_ui/src/field_validators.dart';


DAO getEtDao() {
  return DAO(
    uiNameGetter: (dao) => dao.props['numeroET']?.toString() ?? 'Nueva ET',
    classUiNameGetter: (dao) => 'ET',
    fieldGroups: [
      FieldGroup(
        childGroups: [
          FieldGroup(
            fields: {
              'cliente': ComboField(
                uiNameGetter: (field, dao) => 'Cliente',
                validatorsGetter: (field, dao) => [
                  fieldValidatorRequired,
                ],
                possibleValuesGetter: (field, dao) => [
                  DAO(id: 'Cliente 1', uiNameGetter: (dao) => 'Cliente 1', classUiNameGetter: (dao) => 'Cliente',),
                  DAO(id: 'Cliente 2', uiNameGetter: (dao) => 'Cliente 2', classUiNameGetter: (dao) => 'Cliente',),
                  DAO(id: 'Cliente 3', uiNameGetter: (dao) => 'Cliente 3', classUiNameGetter: (dao) => 'Cliente',),
                  DAO(id: 'Cliente 4', uiNameGetter: (dao) => 'Cliente 4', classUiNameGetter: (dao) => 'Cliente',),
                  DAO(id: 'Cliente 5', uiNameGetter: (dao) => 'Cliente 5', classUiNameGetter: (dao) => 'Cliente',),
                ],
              ),
              'servicio': ComboField(
                uiNameGetter: (field, dao) => 'Servicio',
                enabledGetter: (field, dao) => dao.props['tipoDocumento']!.value==null,
                possibleValuesGetter: (field, dao) => [
                  DAO(id: 'FCL', uiNameGetter: (dao) => 'FCL', classUiNameGetter: (dao) => 'Servicio',),
                  DAO(id: 'LCL', uiNameGetter: (dao) => 'LCL', classUiNameGetter: (dao) => 'Servicio',),
                  DAO(id: 'Aéreo', uiNameGetter: (dao) => 'Aéreo', classUiNameGetter: (dao) => 'Servicio',),
                  DAO(id: 'Terrestre', uiNameGetter: (dao) => 'Terrestre', classUiNameGetter: (dao) => 'Servicio',),
                  DAO(id: 'Otro', uiNameGetter: (dao) => 'Otro', classUiNameGetter: (dao) => 'Servicio',),
                ],
              ),
              'incoterm': ComboField(
                uiNameGetter: (field, dao) => 'Incoterm',
                possibleValuesGetter: (field, dao) => [
                  DAO(id: 'EXW', uiNameGetter: (dao) => 'EXW', classUiNameGetter: (dao) => 'Incoterm',),
                  DAO(id: 'FCA', uiNameGetter: (dao) => 'FCA', classUiNameGetter: (dao) => 'Incoterm',),
                  DAO(id: 'CPT', uiNameGetter: (dao) => 'CPT', classUiNameGetter: (dao) => 'Incoterm',),
                  DAO(id: 'CIP', uiNameGetter: (dao) => 'CIP', classUiNameGetter: (dao) => 'Incoterm',),
                  DAO(id: 'DAP', uiNameGetter: (dao) => 'DAP', classUiNameGetter: (dao) => 'Incoterm',),
                ],
              ),
              'origen': ComboField(
                uiNameGetter: (field, dao) => 'Origen',
                validatorsGetter: (field, dao) => [
                      (BuildContext context, DAO dao, Field field) {
                    final servicio = (dao.props['servicio'] as ComboField).value?.id;
                    if (servicio=='FCL' || servicio=='LCL') {
                      return ValidationError(
                        severity: ValidationErrorSeverity.warning,
                        error: 'Para el servicio $servicio, el origen debe ser un puerto',
                      );
                    } else if (servicio=='Aéreo') {
                      return ValidationError(
                        severity: ValidationErrorSeverity.nonBlockingError,
                        error: 'Para el servicio $servicio, el origen debe ser un aeropuerto',
                      );
                    }
                  }
                ],
                possibleValuesGetter: (field, dao) => [
                  DAO(id: 'Lugar 1', uiNameGetter: (dao) => 'Lugar 1', classUiNameGetter: (dao) => 'Origen',),
                  DAO(id: 'Lugar 2', uiNameGetter: (dao) => 'Lugar 2', classUiNameGetter: (dao) => 'Origen',),
                  DAO(id: 'Lugar 3', uiNameGetter: (dao) => 'Lugar 3', classUiNameGetter: (dao) => 'Origen',),
                  DAO(id: 'Lugar 4', uiNameGetter: (dao) => 'Lugar 4', classUiNameGetter: (dao) => 'Origen',),
                  DAO(id: 'Lugar 5', uiNameGetter: (dao) => 'Lugar 5', classUiNameGetter: (dao) => 'Origen',),
                ],
              ),
              'destino': ComboField(
                uiNameGetter: (field, dao) => 'Destino',
                possibleValuesGetter: (field, dao) => [
                  DAO(id: 'Lugar 1', uiNameGetter: (dao) => 'Lugar 1', classUiNameGetter: (dao) => 'Destino',),
                  DAO(id: 'Lugar 2', uiNameGetter: (dao) => 'Lugar 2', classUiNameGetter: (dao) => 'Destino',),
                  DAO(id: 'Lugar 3', uiNameGetter: (dao) => 'Lugar 3', classUiNameGetter: (dao) => 'Destino',),
                  DAO(id: 'Lugar 4', uiNameGetter: (dao) => 'Lugar 4', classUiNameGetter: (dao) => 'Destino',),
                  DAO(id: 'Lugar 5', uiNameGetter: (dao) => 'Lugar 5', classUiNameGetter: (dao) => 'Destino',),
                ],
              ),
            },
          ),
          FieldGroup(
            primary: false,
            fields: {
              'fechaSalida': DateField(
                uiNameGetter: (field, dao) => 'Fecha Salida',
                maxWidth: 416,
                enabledGetter: (field, dao) => dao.props['fechaSalidaConfirmada']!.value!=true.comparable,
              ),
              'fechaSalidaConfirmada': BoolField(
                uiNameGetter: (field, dao) => 'Confirmación de Salida',
                uiNameTrueGetter: (field, dao) => 'Salida Confirmada',
                uiNameFalseGetter: (field, dao) => 'Salida Sin Confirmar',
                displayType: BoolFieldDisplayType.compactCheckBox,
                enabledGetter: (field, dao) {
                  DateField salida = dao.props['fechaSalida'] as DateField;
                  return salida.value!=null && salida.validationErrors.isEmpty;
                },
                validatorsGetter: (field, dao) => [
                  (BuildContext context, DAO dao, Field<BoolComparable> field) {
                    if (field.value==true.comparable && dao.props['fechaSalida']!.value==null) {
                      return InvalidatingError(
                        error: 'No se puede confirmar una Fecha de Salida desconocida.',
                        showVisualConfirmation: false,
                        defaultValue: false.comparable,
                      );
                    }
                  },
                ],
              ),
            }
          ),
          FieldGroup(
            primary: false,
            fields: {
              'fechaArribo': DateField(
                uiNameGetter: (field, dao) => 'Fecha Arribo',
                maxWidth: 416,
                enabledGetter: (field, dao) => dao.props['fechaSalida']!.value!=null
                                              && dao.props['fechaArriboConfirmada']!.value!=true.comparable,
                validatorsGetter: (field, dao) => [
                  (BuildContext context, DAO dao, Field<DateTime> field) {
                    final salida = (dao.props['fechaSalida'] as DateField).value;
                    if (field.value!=null && salida==null) {
                      return InvalidatingError(
                        error: 'No puede existir una Fecha de Arribo si no se ha especificado la Fecha de Salida.',
                      );
                    } else if (field.value!=null && salida!=null && field.value!.isBefore(salida)) {
                      return ValidationError(
                        error: 'La Fecha de Arribo no puede ser posterior a la Fecha de Salida.',
                      );
                    }
                  },
                ],
              ),
              'fechaArriboConfirmada': BoolField(
                uiNameGetter: (field, dao) => 'Confirmación de Arribo',
                uiNameTrueGetter: (field, dao) => 'Arribo Confirmado',
                uiNameFalseGetter: (field, dao) => 'Arribo Sin Confirmar',
                displayType: BoolFieldDisplayType.compactCheckBox,
                enabledGetter: (field, dao) {
                  DateField arribo = dao.props['fechaArribo'] as DateField;
                  return arribo.value!=null && arribo.validationErrors.isEmpty;
                },
                validatorsGetter: (field, dao) => [
                  (BuildContext context, DAO dao, Field<BoolComparable> field) {
                    if (field.value==true.comparable && dao.props['fechaArribo']!.value==null) {
                      return InvalidatingError(
                        error: 'No se puede confirmar una Fecha de Arribo desconocida.',
                        showVisualConfirmation: false,
                        defaultValue: false.comparable,
                      );
                    }
                  },
                ],
              ),
            },
          ),
          FieldGroup(
            fields: {
              //TODO comercialEncargado
              'notas': StringField(
                uiNameGetter: (field, dao) => 'Notas',
                type: StringFieldType.long,
              ),
            },
          ),
        ],
      ),
      FieldGroup(
        primary: false,
        name: 'Carga',
        fields: {
          'bultos': NumField(
            hiddenGetter: (field, dao) => (dao.props['tipoDocumento'] as ComboField).value==null,
            uiNameGetter: (field, dao) => 'Bultos',
          ),
          'peso': NumField(
            hiddenGetter: (field, dao) => (dao.props['tipoDocumento'] as ComboField).value==null,
            uiNameGetter: (field, dao) => 'Peso',
            digitsAfterComma: 2,
          ),
          'volumen': NumField(
            hiddenGetter: (field, dao) => (dao.props['tipoDocumento'] as ComboField).value==null,
            uiNameGetter: (field, dao) {
              final value = (dao.props['servicio'] as ComboField).value?.id;
              return value=='Aéreo' ? 'Kilovolumen' : 'Volumen';
            },
            digitsAfterComma: 2,
          ),
          // TODO isImo
          // TODO isCargaNoComercial
          'mercancia': StringField(
            hiddenGetter: (field, dao) => (dao.props['tipoDocumento'] as ComboField).value==null,
            uiNameGetter: (field, dao) => 'Mercancía',
            type: StringFieldType.long,
          ),
        },
      ),
      FieldGroup(
        primary: false,
        name: 'Documento',
        fields: {
          'tipoDocumento': ComboField(
            uiNameGetter: (field, dao) => 'Tipo de Documento',
            hiddenGetter: (field, dao) {
              final value = (dao.props['servicio'] as ComboField).value?.id;
              return value!='FCL' && value!='LCL' && value!='Aéreo';
            },
            possibleValuesGetter: (field, dao) {
              final value = (dao.props['servicio'] as ComboField).value?.id;
              if (value=='FCL') {
                return [
                  DAO(id: 'BL Directo', uiNameGetter: (dao) => 'BL Directo', classUiNameGetter: (dao) => 'Tipo de Documento',),
                  DAO(id: 'Master BL', uiNameGetter: (dao) => 'Master BL', classUiNameGetter: (dao) => 'Tipo de Documento',),
                  DAO(id: 'House BL', uiNameGetter: (dao) => 'House BL', classUiNameGetter: (dao) => 'Tipo de Documento',),
                ];
              } else if (value=='LCL') {
                return [
                  DAO(id: 'BL Directo', uiNameGetter: (dao) => 'BL Directo', classUiNameGetter: (dao) => 'Tipo de Documento',),
                  DAO(id: 'Master BL', uiNameGetter: (dao) => 'Master BL', classUiNameGetter: (dao) => 'Tipo de Documento',),
                  DAO(id: 'House BL', uiNameGetter: (dao) => 'House BL', classUiNameGetter: (dao) => 'Tipo de Documento',),
                  DAO(id: 'Submaster BL', uiNameGetter: (dao) => 'Submaster BL', classUiNameGetter: (dao) => 'Tipo de Documento',),
                ];
              } else if (value=='Aéreo') {
                return [
                  DAO(id: 'AWB Directo', uiNameGetter: (dao) => 'AWB Directo', classUiNameGetter: (dao) => 'Tipo de Documento',),
                  DAO(id: 'Master AWB', uiNameGetter: (dao) => 'Master AWB', classUiNameGetter: (dao) => 'Tipo de Documento',),
                  DAO(id: 'House AWB', uiNameGetter: (dao) => 'House AWB', classUiNameGetter: (dao) => 'Tipo de Documento',),
                ];
              }
              return [];
            },
          ),
          'numeroBL': StringField(
            hiddenGetter: (field, dao) => (dao.props['tipoDocumento'] as ComboField).value==null,
            enabledGetter: (field, dao) => false,
            uiNameGetter: (field, dao) {
              final value = (dao.props['servicio'] as ComboField).value?.id;
              return value=='Aéreo' ? 'Número AWB' : 'Número BL';
            },
          ),
          // TODO isRetenido
          // TODO fechaLiberacion
          // TODO tipoEmision
          // TODO tipoPago
          // TODO bool desglosar; // only House Maritimo
          // TODO fechaDesagrupe; // solo LCL
        }
      ),
      FieldGroup(
        primary: false,
        name: 'Contenedores',
        fields: {
          'contenedores': OneToManyRelationField(
            uiNameGetter: (field, dao) => 'Contenedores',
            tableCellsEditable: true,
            hiddenGetter: (field, dao) {
              if ((dao.props['tipoDocumento'] as ComboField).value==null) {
                return true;
              }
              final servicio = (dao.props['servicio'] as ComboField).value?.id;
              if (servicio=='FCL' || servicio=='LCL') {
                return false;
              } else {
                return true;
              }
            },
            objectTemplate: DAO(
              uiNameGetter: (dao) => (dao.props['numeroCont'] as StringField).value ?? '',
              classUiNameGetter: (dao) => 'Contenedor',
              fieldGroups: [
                FieldGroup(
                  fields: {
                    'numeroCont': StringField(
                      uiNameGetter: (field, dao) => 'Número Contenedor',
                    ),
                  },
                ),
              ],
            ),
          ),
        },
      ),
    ]
  );
}