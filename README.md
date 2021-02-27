# environment_register_validation
Postgis/PyQgis geographic project validation/visualization suite

TO DO:
Change inner to left join on create and populate imóveis  lote_atp 

Incluir verificação de ultima inscrição retificada na tabela entrega_xx.atp_lote (caso cod_imovel repetido na tabela entrega_xx.simlam, data da inscrição cancelada mais recente else data da inscrição valida)


WITH tab_min AS ( 
SELECT s.cod_imovel, MIN(s.data_envio) AS minimo
FROM sicar_07.simlam s
WHERE s.cod_imovel IS NOT NULL
GROUP BY s.cod_imovel),


SELECT n.cod_imovel, n.minimo AS primeiro_envio, x.data_envio 
FROM tab_min n
INNER JOIN entrega_07.lote_atp x
ON n.cod_imovel = x.cod_imovel
