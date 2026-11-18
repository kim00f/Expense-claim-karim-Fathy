@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'projection receipt'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true
define view entity ZC_KF_EC_RECEIPT as projection on ZR_KF_EC_RECEIPT
{
    key receipt_uuid,
    line_uuid,
    claim_uuid,
       @Semantics.largeObject: {
    fileName: 'filename' ,
    mimeType: 'mimetype',
    acceptableMimeTypes : [ 'application/pdf' ]}
    receipt_file,
    filename,
    mimetype,
    notes,
    uploaded_by,
    uploaded_at,
    /* Associations */
    _claim : redirected to ZC_KF_EC_CLAIM,
    _line : redirected to parent ZC_KF_EC_LINE
}
