@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'CDS FOR RECEIPTS'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZR_KF_EC_RECEIPT as select from zkf_ec_receipt

association to parent ZR_KF_EC_LINE as _line on $projection.line_uuid = _line.line_uuid

association to ZR_KF_EC_CLAIM as _claim
    on $projection.claim_uuid = _claim.claim_uuid

{
    key receipt_uuid ,
    line_uuid ,
    claim_uuid,
    
      @Semantics.largeObject: {
    fileName: 'filename' ,
    mimeType: 'mimetype',
    acceptableMimeTypes : [ 'application/pdf' ]}
    
    
    receipt_file ,
    filename ,
    mimetype ,
    notes ,
    @Semantics.user.createdBy: true
    uploaded_by,

    @Semantics.systemDateTime.createdAt: true
    uploaded_at,

    _line,
    _claim // Make association public
}
