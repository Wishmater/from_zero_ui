import 'package:flutter/material.dart';
import 'package:from_zero_ui/from_zero_ui.dart';


DAO getEtDao() {
  return DAO(
    uiNameGetter: (dao) => dao.props['numeroET']?.toString() ?? 'Nueva ET',
    classUiNameGetter: (dao) => 'ET',
    fieldGroups: [
      FieldGroup(
        childGroups: [
          FieldGroup(
            fields: {
              'oficina': ComboField(
                value: DAO(id: 'MPG Cuba', uiNameGetter: (dao) => 'MPG Cuba', classUiNameGetter: (dao) => 'Oficina MPG',),
                uiNameGetter: (field, dao) => 'Oficina Gestora',
                clearableGetter: (field, dao) => false,
                validatorsGetter: (field, dao) => [
                  fieldValidatorRequired,
                ],
                possibleValuesGetter: (field, dao) => [
                  DAO(id: 'MPG Cuba', uiNameGetter: (dao) => 'MPG Cuba', classUiNameGetter: (dao) => 'Oficina MPG',),
                  DAO(id: 'MPG Madrid', uiNameGetter: (dao) => 'MPG Madrid', classUiNameGetter: (dao) => 'Oficina MPG',),
                  DAO(id: 'MPG Barcelona', uiNameGetter: (dao) => 'MPG Barcelona', classUiNameGetter: (dao) => 'Oficina MPG',),
                ],
              ),
            }
          ),
          FieldGroup(
            primary: false,
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
              'clienteAvisar': BoolField(
                // set value to entity default when entity is set
                uiNameGetter: (field, dao) => 'Avisar',
                uiNameTrueGetter: (field, dao) => 'Avisar',
                uiNameFalseGetter: (field, dao) => 'No Avisar',
                maxWidth: 64,
                minWidth: 64,
                displayType: BoolFieldDisplayType.compactCheckBox,
                validatorsGetter: (field, dao) => [
                  (context, dao, field,) {
                    if (dao.props['cliente']!.value==null) {
                      return ValidationError(
                        field: field,
                        error: '',
                        severity: ValidationErrorSeverity.disabling,
                      );
                    }
                  },
                  (BuildContext context, DAO dao, Field<BoolComparable> field) {
                    if (field.value==true.comparable && dao.props['cliente']!.value==null) {
                      return InvalidatingError(
                        field: field,
                        error: 'No se puede avisar a una entidad desconocida',
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
              'servicio': ComboField(
                sort: false,
                uiNameGetter: (field, dao) => 'Servicio',
                validatorsGetter: (field, dao) => [
                  (context, dao, field,) {
                    if (dao.props['tipoDocumento']!.value!=null) {
                      return ValidationError(
                        field: field,
                        severity: ValidationErrorSeverity.disabling,
                        error: 'No se puede cambiar el Servicio si ya se especificó el Tipo de Documento',
                      );
                    }
                  },
                  fieldValidatorRequired,
                ],
                possibleValuesGetter: (field, dao) => [
                  DAO(id: 'FCL', uiNameGetter: (dao) => 'FCL', classUiNameGetter: (dao) => 'Servicio',),
                  DAO(id: 'LCL', uiNameGetter: (dao) => 'LCL', classUiNameGetter: (dao) => 'Servicio',),
                  DAO(id: 'Aéreo', uiNameGetter: (dao) => 'Aéreo', classUiNameGetter: (dao) => 'Servicio',),
                  DAO(id: 'Terrestre', uiNameGetter: (dao) => 'Terrestre', classUiNameGetter: (dao) => 'Servicio',),
                  DAO(id: 'Otro', uiNameGetter: (dao) => 'Otro', classUiNameGetter: (dao) => 'Servicio',),
                ],
              ),
              'origen': ComboField(
                uiNameGetter: (field, dao) => 'Origen',
                validatorsGetter: (field, dao) => [
                  (BuildContext context, DAO dao, Field field) {
                    final servicio = (dao.props['servicio'] as ComboField).value?.id;
                    if (field.value!=null) {
                      if (servicio=='Aéreo') {
                        return ValidationError(
                          field: field,
                          severity: ValidationErrorSeverity.nonBlockingError,
                          error: 'Para el servicio $servicio, el origen debe ser un aeropuerto',
                        );
                      }
                    }
                  },
                  (context, dao, field,) => fieldValidatorRequired(context, dao, field, severity: ValidationErrorSeverity.unfinished),
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
                validatorsGetter: (field, dao) => [
                  (context, dao, field,) => fieldValidatorRequired(context, dao, field, severity: ValidationErrorSeverity.unfinished),
                ],
              ),
            },
          ),
          FieldGroup(
            primary: false,
            fields: {
              'fechaSalida': DateField(
                uiNameGetter: (field, dao) => 'Fecha Salida',
                validatorsGetter: (field, dao) => [
                  (context, dao, field,) {
                    if (dao.props['fechaSalidaConfirmada']!.value==true.comparable) {
                      return ValidationError(
                        field: field,
                        severity: ValidationErrorSeverity.disabling,
                        error: 'No se puede cambiar la Fecha de Salida una vez confirmada',
                      );
                    }
                  },
                  (context, dao, field,) => fieldValidatorRequired(context, dao, field, severity: ValidationErrorSeverity.unfinished),
                ],
              ),
              'fechaSalidaConfirmada': BoolField(
                uiNameGetter: (field, dao) => 'Confirmación de Salida',
                uiNameTrueGetter: (field, dao) => 'Salida Confirmada',
                uiNameFalseGetter: (field, dao) => 'Salida Sin Confirmar',
                displayType: BoolFieldDisplayType.compactCheckBox,
                validatorsGetter: (field, dao) => [
                  (context, dao, field,) {
                    DateField salida = dao.props['fechaSalida'] as DateField;
                    if (salida.value==null || salida.validationErrors.where((e) => e.isBlocking).isNotEmpty) {
                      return ValidationError(
                        field: field,
                        severity: ValidationErrorSeverity.disabling,
                        error: '',
                      );
                    }
                  },
                  (BuildContext context, DAO dao, Field<BoolComparable> field) {
                    if (field.value==true.comparable && dao.props['fechaSalida']!.value==null) {
                      return InvalidatingError(
                        field: field,
                        error: 'No se puede confirmar una Fecha de Salida desconocida',
                        showVisualConfirmation: false,
                        defaultValue: false.comparable,
                      );
                    }
                  },
                  (context, dao, field,) {
                    DateField salida = dao.props['fechaSalida'] as DateField;
                    if (salida.value!=null) {
                      return fieldValidatorRequired(context, dao, field, severity: ValidationErrorSeverity.unfinished);
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
                validatorsGetter: (field, dao) => [
                  (context, dao, field,) {
                    if (dao.props['fechaSalida']!.value==null) {
                      return ValidationError(
                        field: field,
                        severity: ValidationErrorSeverity.disabling,
                        error: 'No se puede especificar la Fecha de Arribo antes de especificar la Fecha de Salida',
                      );
                    }
                  },
                  (context, dao, field,) {
                    if (dao.props['fechaArriboConfirmada']!.value==true.comparable) {
                      return ValidationError(
                        field: field,
                        severity: ValidationErrorSeverity.disabling,
                        error: 'No se puede cambiar la Fecha de Arribo una vez confirmada',
                      );
                    }
                  },
                  (BuildContext context, DAO dao, Field<DateTime> field) {
                    final salida = (dao.props['fechaSalida'] as DateField).value;
                    if (field.value!=null && salida==null) {
                      return InvalidatingError(
                        field: field,
                        error: 'No puede existir una Fecha de Arribo si no se ha especificado la Fecha de Salida',
                      );
                    } else if (field.value!=null && salida!=null && field.value!.isBefore(salida)) {
                      return ValidationError(
                        field: field,
                        error: 'La Fecha de Arribo no puede ser anterior a la Fecha de Salida',
                      );
                    }
                  },
                  (context, dao, field,) => fieldValidatorRequired(context, dao, field, severity: ValidationErrorSeverity.unfinished),
                ],
              ),
              'fechaArriboConfirmada': BoolField(
                uiNameGetter: (field, dao) => 'Confirmación de Arribo',
                uiNameTrueGetter: (field, dao) => 'Arribo Confirmado',
                uiNameFalseGetter: (field, dao) => 'Arribo Sin Confirmar',
                displayType: BoolFieldDisplayType.compactCheckBox,
                validatorsGetter: (field, dao) => [
                  (context, dao, field,) {
                    DateField arribo = dao.props['fechaArribo'] as DateField;
                    if (arribo.value==null || arribo.validationErrors.where((e) => e.isBlocking).isNotEmpty) {
                      return ValidationError(
                        field: field,
                        severity: ValidationErrorSeverity.disabling,
                        error: '',
                      );
                    }
                  },
                  (BuildContext context, DAO dao, Field<BoolComparable> field) {
                    if (field.value==true.comparable && dao.props['fechaArribo']!.value==null) {
                      return InvalidatingError(
                        field: field,
                        error: 'No se puede confirmar una Fecha de Arribo desconocida',
                        showVisualConfirmation: false,
                        defaultValue: false.comparable,
                      );
                    }
                  },
                  (context, dao, field,) {
                    DateField arribo = dao.props['fechaArribo'] as DateField;
                    if (arribo.value!=null) {
                      return fieldValidatorRequired(context, dao, field, severity: ValidationErrorSeverity.unfinished);
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
          name: 'Documento',
          fields: {
            'tipoDocumento': ComboField(
              sort: false,
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
              uiNameGetter: (field, dao) {
                final value = (dao.props['servicio'] as ComboField).value?.id;
                return value=='Aéreo' ? 'Número AWB' : 'Número BL';
              },
            ),
            'isRetenido': BoolField(
              uiNameGetter: (field, dao) => 'Retenido',
              hiddenGetter: (field, dao) => (dao.props['tipoDocumento'] as ComboField).value==null,
              uiNameFalseGetter: (field, dao) => 'Sin Retener',
              uiNameTrueGetter: (field, dao) => 'Retenido',
              showBothNeutralAndSpecificUiName: false,
              displayType: BoolFieldDisplayType.switchTile,
              selectedColor: (context, field, dao) => ValidationMessage.severityColors[Theme.of(context).brightness]![ValidationErrorSeverity.error]!,
              backgroundColor: (context, field, dao) => field.value!=true.comparable ? null
                  : ValidationMessage.severityColors[Theme.of(context).brightness.inverse]![ValidationErrorSeverity.error]!.withOpacity(0.2),
              validatorsGetter: (field, dao) => [
                (context, dao, field,) {
                  if (dao.props['fechaLiberacion']!.value!=null) {
                    return ValidationError(
                      field: field,
                      error: 'No se puede retener un documento que ya fue liberado',
                      severity: ValidationErrorSeverity.disabling,
                    );
                  }
                },
              ],
            ),
            'fechaLiberacion': DateField(
              uiNameGetter: (field, dao) => 'Fecha Liberación',
              hiddenGetter: (field, dao) => (dao.props['tipoDocumento'] as ComboField).value==null,
              validatorsGetter: (field, dao) => [
                (context, dao, field,) {
                  if (dao.props['isRetenido']!.value==true.comparable) {
                    return ValidationError(
                      field: field,
                      severity: ValidationErrorSeverity.disabling,
                      error: 'No se puede liberar un documento retenido',
                    );
                  }
                },
                (context, dao, field,) => fieldValidatorRequired(context, dao, field,
                  severity: ValidationErrorSeverity.unfinished,
                  errorMessage: 'Fecha de Liberación no ha sido especificada',
                ),
              ],
            ),
            'incoterm': ComboField(
              sort: false,
              uiNameGetter: (field, dao) => 'Incoterm',
              hiddenGetter: (field, dao) => (dao.props['tipoDocumento'] as ComboField).value==null, // TODO 3 hide if not embarque
              possibleValuesGetter: (field, dao) => [
                DAO(id: 'EXW', uiNameGetter: (dao) => 'EXW', classUiNameGetter: (dao) => 'Incoterm',),
                DAO(id: 'FCA', uiNameGetter: (dao) => 'FCA', classUiNameGetter: (dao) => 'Incoterm',),
                DAO(id: 'CPT', uiNameGetter: (dao) => 'CPT', classUiNameGetter: (dao) => 'Incoterm',),
                DAO(id: 'CIP', uiNameGetter: (dao) => 'CIP', classUiNameGetter: (dao) => 'Incoterm',),
                DAO(id: 'DAP', uiNameGetter: (dao) => 'DAP', classUiNameGetter: (dao) => 'Incoterm',),
              ],
              validatorsGetter: (field, dao) => [
                    (context, dao, field,) => fieldValidatorRequired(context, dao, field, severity: ValidationErrorSeverity.unfinished),
              ],
            ),
            'emision': ComboField(
              sort: false,
              uiNameGetter: (field, dao) => 'Emisión',
              hiddenGetter: (field, dao) => (dao.props['tipoDocumento'] as ComboField).value==null,
              possibleValuesGetter: (field, dao) => [
                DAO(id: "Origen", uiNameGetter: (dao) => "Origen", classUiNameGetter: (dao) => 'Emisión',),
                DAO(id: "Destino", uiNameGetter: (dao) => "Destino", classUiNameGetter: (dao) => 'Emisión',),
              ],
              validatorsGetter: (field, dao) => [fieldValidatorRequired],
            ),
            'tipoPago': ComboField(
              sort: false,
              uiNameGetter: (field, dao) => 'Términos',
              hiddenGetter: (field, dao) => (dao.props['tipoDocumento'] as ComboField).value==null,
              possibleValuesGetter: (field, dao) => [
                DAO(id: "Prepaid", uiNameGetter: (dao) => "Prepaid", classUiNameGetter: (dao) => 'Forma de Pago',),
                DAO(id: "Collect", uiNameGetter: (dao) => "Collect", classUiNameGetter: (dao) => 'Forma de Pago',),
                DAO(id: "Elsewhere", uiNameGetter: (dao) => "Elsewhere", classUiNameGetter: (dao) => 'Forma de Pago',),
              ],
              validatorsGetter: (field, dao) => [fieldValidatorRequired],
            ),
            'responsablePago': ComboField( // TODO 3 hide if Directo
              sort: false,
              uiNameGetter: (field, dao) => 'Responsable',
              hiddenGetter: (field, dao) => (dao.props['tipoDocumento'] as ComboField).value==null,
              possibleValuesGetter: (field, dao) => [
                DAO(id: "Cliente", uiNameGetter: (dao) => "Cliente", classUiNameGetter: (dao) => 'Responsable de Pago',),
                DAO(id: "Agente", uiNameGetter: (dao) => "Agente", classUiNameGetter: (dao) => 'Responsable de Pago',),
                DAO(id: "Consignatario", uiNameGetter: (dao) => "Consignatario", classUiNameGetter: (dao) => 'Responsable de Pago',),
              ],
              validatorsGetter: (field, dao) => [fieldValidatorRequired],
            ),
            'fechaDesagrupe': DateField(
              uiNameGetter: (field, dao) => 'Fecha Desagrupe',
              hiddenGetter: (field, dao) => (dao.props['servicio'] as ComboField).value.toString()!='LCL' || (dao.props['tipoDocumento'] as ComboField).value==null,
              validatorsGetter: (field, dao) => [
                (context, dao, field,) => fieldValidatorRequired(context, dao, field,
                  severity: ValidationErrorSeverity.unfinished,
                  errorMessage: 'Fecha de Desagrupe no ha sido especificada',
                ),
              ],
            ),
            // TODO buqueViaje / trasbordos / escalas
            // TODO bool desglosar; // only House Maritimo
            // TODO notaPrealerta; // only Master
          }
      ),
      FieldGroup(
        primary: false,
        name: 'Carga',
        childGroups: [
          FieldGroup(
            primary: false,
            fields: {
              'bultos': NumField(
                uiNameGetter: (field, dao) => 'Bultos',
                hiddenGetter: (field, dao) => (dao.props['tipoDocumento'] as ComboField).value==null,
                validatorsGetter: (field, dao) => [fieldValidatorRequired, fieldValidatorNumberNotZero, fieldValidatorNumberNotNegative],
              ),
              'peso': NumField(
                uiNameGetter: (field, dao) => 'Peso',
                hiddenGetter: (field, dao) => (dao.props['tipoDocumento'] as ComboField).value==null,
                digitsAfterComma: 2,
                validatorsGetter: (field, dao) => [fieldValidatorRequired, fieldValidatorNumberNotZero, fieldValidatorNumberNotNegative],
              ),
              'volumen': NumField(
                uiNameGetter: (field, dao) {
                  final value = (dao.props['servicio'] as ComboField).value?.id;
                  return value=='Aéreo' ? 'Kilovolumen' : 'Volumen';
                },
                hiddenGetter: (field, dao) => (dao.props['tipoDocumento'] as ComboField).value==null,
                digitsAfterComma: 2,
                validatorsGetter: (field, dao) => [fieldValidatorRequired, fieldValidatorNumberNotZero, fieldValidatorNumberNotNegative],
              ),
            }
          ),
          FieldGroup(
            primary: false,
            fields: {
              'isNoComercial': BoolField(
                uiNameGetter: (field, dao) => 'Carga No Comercial',
                hiddenGetter: (field, dao) => (dao.props['tipoDocumento'] as ComboField).value==null,
              ),
              'isIMO': BoolField(
                uiNameGetter: (field, dao) => 'Carga IMO',
                hiddenGetter: (field, dao) => (dao.props['tipoDocumento'] as ComboField).value==null,
              ),
            },
          ),
          FieldGroup(
            fields: {
              'mercancia': StringField(
                uiNameGetter: (field, dao) => 'Mercancía',
                hiddenGetter: (field, dao) => (dao.props['tipoDocumento'] as ComboField).value==null,
                type: StringFieldType.long,
              ),
              'contenedores': ListField(
                uiNameGetter: (field, dao) => 'Contenedores',
                objects: [],
                tableCellsEditable: true,
                initialSortColumn: -1,
                skipDeleteConfirmation: true,
                tableFilterable: false,
                actionDeleteBreakpoints: {0: ActionState.icon},
                actionDuplicateBreakpoints: {0: ActionState.icon},
                actionEditBreakpoints: {0: ActionState.icon},
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
                  classUiNamePluralGetter: (dao) => 'Contenedores',
                  fieldGroups: [
                    FieldGroup(
                      fields: {
                        'numeroCont': StringField(
                          clearableGetter: (field, dao) => false,
                          tableColumnWidth: 160,
                          uiNameGetter: (field, dao) => 'Número Contenedor',
                          validatorsGetter: (field, dao) => [fieldValidatorRequired],
                        ),
                        'tipoCont': ComboField(
                          sort: false,
                          clearableGetter: (field, dao) => false,
                          uiNameGetter: (field, dao) => 'Tipo',
                          tableColumnWidth: 96,
                          possibleValuesGetter: (field, dao) => [
                            DAO(id: "20' DV", uiNameGetter: (dao) => "20' DV", classUiNameGetter: (dao) => 'Tipo de Contenedor',),
                            DAO(id: "40' DV", uiNameGetter: (dao) => "40' DV", classUiNameGetter: (dao) => 'Tipo de Contenedor',),
                          ],
                          validatorsGetter: (field, dao) => [fieldValidatorRequired],
                        ),
                        'bultos': NumField(
                          clearableGetter: (field, dao) => false,
                          uiNameGetter: (field, dao) => 'Bultos',
                          tableColumnWidth: 64,
                          validatorsGetter: (field, dao) => [fieldValidatorRequired, fieldValidatorNumberNotZero, fieldValidatorNumberNotNegative],
                        ),
                        'peso': NumField(
                          clearableGetter: (field, dao) => false,
                          uiNameGetter: (field, dao) => 'Peso',
                          tableColumnWidth: 64,
                          digitsAfterComma: 2,
                          validatorsGetter: (field, dao) => [fieldValidatorRequired, fieldValidatorNumberNotZero, fieldValidatorNumberNotNegative],
                        ),
                        'volumen': NumField(
                          clearableGetter: (field, dao) => false,
                          uiNameGetter: (field, dao) => 'Volumen',
                          tableColumnWidth: 80,
                          digitsAfterComma: 2,
                          validatorsGetter: (field, dao) => [fieldValidatorRequired, fieldValidatorNumberNotZero, fieldValidatorNumberNotNegative],
                        ),
                        // TODO sellos
                      },
                    ),
                  ],
                ),
              ),
            },
          ),
        ],
      ),
      FieldGroup(
        primary: false,
        name: 'Entidades',
        childGroups: [
          FieldGroup(
            primary: false,
            fields: {
              'transportista': ComboField(
                uiNameGetter: (field, dao) => dao.props['servicio']!.value=='Aereo' ? 'Aerolínea' : 'Naviera',
                hiddenGetter: (field, dao) => (dao.props['tipoDocumento'] as ComboField).value==null,
                possibleValuesGetter: (field, dao) => [
                  DAO(id: "Entidad 1", uiNameGetter: (dao) => "Entidad 1", classUiNameGetter: (dao) => 'Entidad',),
                  DAO(id: "Entidad 2", uiNameGetter: (dao) => "Entidad 2", classUiNameGetter: (dao) => 'Entidad',),
                  DAO(id: "Entidad 3", uiNameGetter: (dao) => "Entidad 3", classUiNameGetter: (dao) => 'Entidad',),
                ],
                validatorsGetter: (field, dao) => [fieldValidatorRequired],
              ),
            },
          ),
          FieldGroup(
            primary: false,
            fields: {
              'agente': ComboField(
                uiNameGetter: (field, dao) => 'Agente',
                hiddenGetter: (field, dao) => (dao.props['tipoDocumento'] as ComboField).value==null,
                possibleValuesGetter: (field, dao) => [
                  DAO(id: "Entidad 1", uiNameGetter: (dao) => "Entidad 1", classUiNameGetter: (dao) => 'Entidad',),
                  DAO(id: "Entidad 2", uiNameGetter: (dao) => "Entidad 2", classUiNameGetter: (dao) => 'Entidad',),
                  DAO(id: "Entidad 3", uiNameGetter: (dao) => "Entidad 3", classUiNameGetter: (dao) => 'Entidad',),
                ],
                validatorsGetter: (field, dao) => [fieldValidatorRequired],
              ),
              'agenteAvisar': BoolField(
                // set value to entity default when entity is set
                uiNameGetter: (field, dao) => 'Avisar',
                uiNameTrueGetter: (field, dao) => 'Avisar',
                uiNameFalseGetter: (field, dao) => 'No Avisar',
                maxWidth: 64,
                minWidth: 64,
                hiddenGetter: (field, dao) => (dao.props['tipoDocumento'] as ComboField).value==null,
                displayType: BoolFieldDisplayType.compactCheckBox,
                validatorsGetter: (field, dao) => [
                  (context, dao, field,) {
                    if (dao.props['agente']!.value==null) {
                      return ValidationError(
                        field: field,
                        error: '',
                        severity: ValidationErrorSeverity.disabling,
                      );
                    }
                  },
                  (BuildContext context, DAO dao, Field<BoolComparable> field) {
                    if (field.value==true.comparable && dao.props['agente']!.value==null) {
                      return InvalidatingError(
                        field: field,
                        error: 'No se puede avisar a una entidad desconocida',
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
            primary: false,
            fields: {
              'embarcador': ComboField(
                uiNameGetter: (field, dao) => 'Embarcador',
                hiddenGetter: (field, dao) => (dao.props['tipoDocumento'] as ComboField).value==null,
                possibleValuesGetter: (field, dao) => [
                  DAO(id: "Entidad 1", uiNameGetter: (dao) => "Entidad 1", classUiNameGetter: (dao) => 'Entidad',),
                  DAO(id: "Entidad 2", uiNameGetter: (dao) => "Entidad 2", classUiNameGetter: (dao) => 'Entidad',),
                  DAO(id: "Entidad 3", uiNameGetter: (dao) => "Entidad 3", classUiNameGetter: (dao) => 'Entidad',),
                ],
                validatorsGetter: (field, dao) => [fieldValidatorRequired],
              ),
              'embarcadorAvisar': BoolField(
                // set value to entity default when entity is set
                uiNameGetter: (field, dao) => 'Avisar',
                uiNameTrueGetter: (field, dao) => 'Avisar',
                uiNameFalseGetter: (field, dao) => 'No Avisar',
                maxWidth: 64,
                minWidth: 64,
                hiddenGetter: (field, dao) => (dao.props['tipoDocumento'] as ComboField).value==null,
                displayType: BoolFieldDisplayType.compactCheckBox,
                validatorsGetter: (field, dao) => [
                  (context, dao, field,) {
                    if (dao.props['embarcador']!.value==null) {
                      return ValidationError(
                        field: field,
                        error: '',
                        severity: ValidationErrorSeverity.disabling,
                      );
                    }
                  },
                  (BuildContext context, DAO dao, Field<BoolComparable> field) {
                    if (field.value==true.comparable && dao.props['embarcador']!.value==null) {
                      return InvalidatingError(
                        field: field,
                        error: 'No se puede avisar a una entidad desconocida',
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
            primary: false,
            fields: {
              'consignatario': ComboField(
                uiNameGetter: (field, dao) => 'Consignatario',
                hiddenGetter: (field, dao) => (dao.props['tipoDocumento'] as ComboField).value==null,
                possibleValuesGetter: (field, dao) => [
                  DAO(id: "Entidad 1", uiNameGetter: (dao) => "Entidad 1", classUiNameGetter: (dao) => 'Entidad',),
                  DAO(id: "Entidad 2", uiNameGetter: (dao) => "Entidad 2", classUiNameGetter: (dao) => 'Entidad',),
                  DAO(id: "Entidad 3", uiNameGetter: (dao) => "Entidad 3", classUiNameGetter: (dao) => 'Entidad',),
                ],
                validatorsGetter: (field, dao) => [fieldValidatorRequired],
              ),
              'consignatarioAvisar': BoolField(
                // set value to entity default when entity is set
                uiNameGetter: (field, dao) => 'Avisar',
                uiNameTrueGetter: (field, dao) => 'Avisar',
                uiNameFalseGetter: (field, dao) => 'No Avisar',
                maxWidth: 64,
                minWidth: 64,
                hiddenGetter: (field, dao) => (dao.props['tipoDocumento'] as ComboField).value==null,
                displayType: BoolFieldDisplayType.compactCheckBox,
                validatorsGetter: (field, dao) => [
                      (context, dao, field,) {
                    if (dao.props['consignatario']!.value==null) {
                      return ValidationError(
                        field: field,
                        error: '',
                        severity: ValidationErrorSeverity.disabling,
                      );
                    }
                  },
                      (BuildContext context, DAO dao, Field<BoolComparable> field) {
                    if (field.value==true.comparable && dao.props['consignatario']!.value==null) {
                      return InvalidatingError(
                        field: field,
                        error: 'No se puede avisar a una entidad desconocida',
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
            primary: false,
            fields: {
              'nacional': ComboField(
                uiNameGetter: (field, dao) => 'Transitario Nacional',
                hiddenGetter: (field, dao) => (dao.props['tipoDocumento'] as ComboField).value==null,
                possibleValuesGetter: (field, dao) => [
                  DAO(id: "Entidad 1", uiNameGetter: (dao) => "Entidad 1", classUiNameGetter: (dao) => 'Entidad',),
                  DAO(id: "Entidad 2", uiNameGetter: (dao) => "Entidad 2", classUiNameGetter: (dao) => 'Entidad',),
                  DAO(id: "Entidad 3", uiNameGetter: (dao) => "Entidad 3", classUiNameGetter: (dao) => 'Entidad',),
                ],
                validatorsGetter: (field, dao) => [fieldValidatorRequired],
              ),
              'nacionalAvisar': BoolField(
                // set value to entity default when entity is set
                uiNameGetter: (field, dao) => 'Avisar',
                uiNameTrueGetter: (field, dao) => 'Avisar',
                uiNameFalseGetter: (field, dao) => 'No Avisar',
                maxWidth: 64,
                minWidth: 64,
                hiddenGetter: (field, dao) => (dao.props['tipoDocumento'] as ComboField).value==null,
                displayType: BoolFieldDisplayType.compactCheckBox,
                validatorsGetter: (field, dao) => [
                  (context, dao, field,) {
                    if (dao.props['nacional']!.value==null) {
                      return ValidationError(
                        field: field,
                        error: '',
                        severity: ValidationErrorSeverity.disabling,
                      );
                    }
                  },
                  (BuildContext context, DAO dao, Field<BoolComparable> field) {
                    if (field.value==true.comparable && dao.props['nacional']!.value==null) {
                      return InvalidatingError(
                        field: field,
                        error: 'No se puede avisar a una entidad desconocida',
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
              'notifies': ListField(
                uiNameGetter: (field, dao) => 'Notify',
                objects: [],
                tableCellsEditable: true,
                initialSortColumn: -1,
                skipDeleteConfirmation: true,
                tableFilterable: false,
                hiddenGetter: (field, dao) => (dao.props['tipoDocumento'] as ComboField).value==null,
                validatorsGetter: (field, dao) => [
                      (context, dao, field,) {
                    final servicio = (dao.props['servicio'] as ComboField).value?.id;
                    final tipoDocumento = (dao.props['tipoDocumento'] as ComboField).value;
                    final objects = (field as ListField).objects;
                    if ((servicio=='FCL' || servicio=='LCL') && tipoDocumento!=null && objects.isEmpty) {
                      return ValidationError(
                        field: field,
                        error: 'Al menos 1 notify requerido',
                      );
                    }
                  },
                ],
                availableObjectsPoolGetter: (context) async => [
                  buildEntidad('1', true),
                  buildEntidad('2', true),
                  buildEntidad('3', false),
                ],
                objectTemplate: buildEntidad('1', true).copyWith(uiNameGetter: (dao) => 'Notify',),
                allowAddNew: false,
              ),
            },
          ),
        ],
      ),
    ]
  );
}

DAO buildEntidad (String name, bool avisar,) {
  return DAO(
    id: "Entidad $name",
    uiNameGetter: (dao) => "Entidad $name",
    classUiNameGetter: (dao) => 'Entidad',
    fieldGroups: [
      FieldGroup(
        fields: {
          'nombre': StringField(
            uiNameGetter: (field, dao) => 'Nombre',
            value: "Entidad $name",
            tableColumnWidth: 256,
            validatorsGetter: (field, dao) => [
              (_, __, ___) {
                return ValidationError(
                  field: field,
                  error: '',
                  severity: ValidationErrorSeverity.disabling,
                );
              },
            ],
          ),
          'avisar': BoolField(
            uiNameGetter: (field, dao) => 'Avisar',
            uiNameTrueGetter: (field, dao) => 'Avisar',
            uiNameFalseGetter: (field, dao) => 'No Avisar',
            tableColumnWidth: 140,
            value: avisar.comparable,
          ),
        }
      ),
    ],
  );
}