ALTER TABLE sicar_XX.simlam
ALTER COLUMN data_emissao TYPE date USING TO_DATE(data_emissao,'DD/MM/YYYY'),
ALTER COLUMN data_envio TYPE date USING TO_DATE(data_envio,'DD/MM/YYYY');

ALTER TABLE sicar_XX.atp
        ADD lote varchar,
        ADD doc_proprietario varchar,
        ADD doc_cadastrante varchar,
        ADD num_solicitacao varchar,
        ADD cod_emp varchar,
        ADD requerimento varchar,
        ADD stat_simlam varchar,
        ADD stat_sicar varchar,
        ADD data_envio date;
        ADD envio_prev date;

UPDATE sicar_XX.atp
   SET doc_proprietario = sicar_XX.relatorio.doc_proprietario
  FROM sicar_XX.relatorio
 WHERE cod_imovel = sicar_XX.relatorio.num_recibo;

UPDATE sicar_XX.atp
   SET doc_cadastrante = sicar_XX.relatorio.doc_cadastrante
  FROM sicar_XX.relatorio
 WHERE cod_imovel = sicar_XX.relatorio.num_recibo;

UPDATE sicar_XX.atp
   SET lote = mn.lote
  FROM municipios AS mn
 WHERE sicar_XX.atp.municipio = mn.municipio;
 
UPDATE sicar_XX.atp
   SET num_solicitacao = s.num_solicitacao
  FROM sicar_XX.simlam AS s
 WHERE sicar_XX.atp.cod_imovel = s.cod_imovel
   AND (s.stat_simlam = 'valido' OR s.stat_simlam = 'substituido');
 
UPDATE sicar_XX.atp
   SET cod_emp = s.cod_emp
  FROM sicar_XX.simlam AS s
 WHERE sicar_XX.atp.cod_imovel = s.cod_imovel
   AND (s.stat_simlam = 'valido' OR s.stat_simlam = 'substituido');

UPDATE sicar_XX.atp
   SET requerimento = s.requerimento
  FROM sicar_XX.simlam AS s
 WHERE sicar_XX.atp.cod_imovel = s.cod_imovel
   AND (s.stat_simlam = 'valido' OR s.stat_simlam = 'substituido');
 
UPDATE sicar_XX.atp
   SET stat_simlam = s.stat_simlam
  FROM sicar_XX.simlam AS s
 WHERE sicar_XX.atp.cod_imovel = s.cod_imovel
   AND (s.stat_simlam = 'valido' OR s.stat_simlam = 'substituido');
 
UPDATE sicar_XX.atp
   SET stat_sicar = s.stat_sicar
  FROM sicar_XX.simlam AS s
 WHERE sicar_XX.atp.cod_imovel = s.cod_imovel
   AND (s.stat_simlam = 'valido' OR s.stat_simlam = 'substituido');
 
UPDATE sicar_XX.atp
   SET data_envio = s.data_envio
  FROM sicar_XX.simlam AS s
 WHERE sicar_XX.atp.cod_imovel = s.cod_imovel
   AND s.stat_sicar = 'arquivo entregue';
   
CREATE TEMPORARY TABLE retificados AS (
                SELECT s.cod_imovel,
                       MAX(s.data_emissao) AS maximo
                  FROM sicar_07.simlam s 
                 WHERE s.stat_sicar = 'arquivo retificado'
              GROUP BY s.cod_imovel);

UPDATE sicar_XX.atp
   SET envio_prev = r.maximo
  FROM retificados AS r
 WHERE sicar_XX.atp.cod_imovel = r.cod_imovel;

CREATE TABLE entrega_XX.lote_atp AS(
      SELECT l.id, 
             l.num_recibo as cod_imovel,
             sa.cod_emp,
             sa.num_solicitacao,
             sa.requerimento,
             sa.municipio,
             sa.lote, 
             sa.mod_fiscal, 
             sa.doc_proprietario, 
             sa.doc_cadastrante,
             sa.data_envio,
             sa.envio_prev,
             sa.stat_simlam,
             sa.stat_sicar,
             sa.geom
        FROM sicar_XX.imoveis l
   LEFT JOIN sicar_XX.atp sa 
          ON l.num_recibo = sa.cod_imovel);

ALTER TABLE entrega_XX.lote_atp
    ADD teste_01 boolean,
    ADD teste_02 boolean,
    ADD teste_03 boolean,
    ADD teste_04 boolean,
    ADD teste_05 boolean,
    ADD teste_06 boolean,
    ADD teste_07 boolean,
    ADD teste_08 boolean,
    ADD teste_09 boolean,
    ADD teste_10 boolean,
    ADD teste_11 boolean,
    ADD teste_12 boolean,
    ADD teste_13 boolean,
    ADD geral boolean;

CREATE TABLE entrega_XX.base_atp AS (
      SELECT sa.id, 
             sa.cod_imovel,
             sa.cod_emp,
             la.municipio, 
             la.lote, 
             la.cod_imovel AS cod_imovel_lote,
             la.cod_emp AS cod_emp_lote,
             sa.doc_proprietario, 
             sa.doc_cadastrante, 
             sa.geom
        FROM sicar_XX.atp sa
        JOIN entrega_XX.lote_atp la
          ON sa.geom && la.geom 
	     AND ST_Intersects(sa.geom, la.geom) 
	     AND sa.cod_imovel != la.cod_imovel);

CREATE TEMPORARY TABLE base_arl_temp AS(
                SELECT sa.id, 
                       sa.cod_imovel, 
                       la.cod_emp,
                       la.municipio, 
                       la.lote, 
                       la.cod_imovel AS cod_imovel_lote,
                       la.cod_emp AS cod_emp_lote,
                       sa.geom
                  FROM sicar_XX.arl sa
                  JOIN entrega_XX.lote_atp la
                    ON sa.geom && la.geom 
                       AND ST_Intersects(sa.geom, la.geom) 
	               AND sa.cod_imovel != la.cod_imovel);

CREATE TABLE entrega_XX.base_arl AS
      SELECT cod_imovel, 
             cod_emp, 
             municipio, 
             lote, 
             cod_imovel_lote,
             cod_emp_lote,
             ST_Multi(ST_Union(base_arl_temp.geom)) AS geom
        FROM base_arl_temp
    GROUP BY cod_imovel, cod_emp, cod_imovel_lote, cod_emp_lote, municipio, lote;
	
CREATE TEMPORARY TABLE lote_arl_temp AS(
                SELECT sr.id, 
                       sr.cod_imovel,
                       la.cod_emp,
                       la.municipio,
                       la.lote,
                       sr.geom
                  FROM sicar_XX.arl sr
                  JOIN entrega_XX.lote_atp la
                    ON la.cod_imovel = sr.cod_imovel);

CREATE TABLE entrega_XX.lote_arl AS
      SELECT cod_imovel,
             cod_emp,
             municipio,
             lote,
             ST_Multi(ST_Union(lote_arl_temp.geom)) AS geom
        FROM lote_arl_temp
    GROUP BY cod_imovel, cod_emp, municipio, lote;

CREATE TEMPORARY TABLE lote_aa_temp AS(
                SELECT sa.id, 
                       sa.cod_imovel,
                       la.cod_emp,
                       la.municipio,
                       la.lote,
                       sa.geom
                  FROM sicar_XX.aa sa
                  JOIN entrega_XX.lote_atp la
                    ON la.cod_imovel = sa.cod_imovel);

CREATE TABLE entrega_XX.lote_aa AS
      SELECT cod_imovel,
             cod_emp,
             municipio,
             lote,
             ST_Multi(ST_Union(lote_aa_temp.geom)) AS geom
        FROM lote_aa_temp
    GROUP BY cod_imovel, cod_emp, municipio, lote;

CREATE TEMPORARY TABLE lote_avn_temp AS(
                SELECT sv.id, 
                       sv.cod_imovel,
                       la.cod_emp,
                       la.municipio,
                       la.lote,
                       sv.geom
                  FROM sicar_XX.avn sv
                  JOIN entrega_XX.lote_atp la
                    ON la.cod_imovel = sv.cod_imovel);

CREATE TABLE entrega_XX.lote_avn AS
      SELECT cod_imovel,
             cod_emp,
             municipio,
             lote,
             ST_Multi(ST_Union(lote_avn_temp.geom)) AS geom
        FROM lote_avn_temp
    GROUP BY cod_imovel, cod_emp, municipio, lote;

CREATE TEMPORARY TABLE lote_hidro_temp AS(
                SELECT sh.id, 
                       sh.cod_imovel,
                       la.cod_emp,
                       la.municipio,
                       la.lote,
                       sh.geom
                  FROM sicar_XX.hidro sh
                  JOIN entrega_XX.lote_atp la
                    ON la.cod_imovel = sh.cod_imovel);

CREATE TABLE entrega_XX.lote_hidro AS
      SELECT cod_imovel,
             cod_emp,
             municipio,
             lote,
             ST_Multi(ST_Union(lote_hidro_temp.geom)) AS geom
        FROM lote_hidro_temp
    GROUP BY cod_imovel, cod_emp, municipio, lote;

CREATE TEMPORARY TABLE lote_app_temp AS(
                SELECT sp.id, 
                       sp.cod_imovel,
                       la.cod_emp,
                       la.municipio,
                       la.lote,
                       sp.geom
                  FROM sicar_XX.app sp
                  JOIN entrega_XX.lote_atp la 
                    ON la.cod_imovel = sp.cod_imovel);

CREATE TABLE entrega_XX.lote_app AS
      SELECT cod_imovel,
             cod_emp,
             municipio,
             lote,
             ST_Multi(ST_Union(lote_app_temp.geom)) AS geom
        FROM lote_app_temp
    GROUP BY cod_imovel, cod_emp, municipio, lote;

CREATE TEMPORARY TABLE uso_solo_temp AS
SELECT cod_imovel, 
       geom
  FROM entrega_XX.lote_aa;

INSERT INTO uso_solo_temp
     SELECT cod_imovel, 
            geom
       FROM entrega_XX.lote_avn;

INSERT INTO uso_solo_temp
     SELECT cod_imovel,
            geom
       FROM entrega_XX.lote_hidro;

CREATE TABLE entrega_XX.uso_solo AS
      SELECT cod_imovel,
             ST_Multi(ST_Union(ST_Buffer(uso_solo_temp.geom, 0.000001))) AS geom
        FROM uso_solo_temp
    GROUP BY cod_imovel;

CREATE TEMPORARY TABLE iema_hidro_temp AS
                SELECT la.id, 
                       la.cod_imovel,
                       la.cod_emp,
                       la.municipio,
                       la.lote,
                       ST_Intersection(ST_Buffer(la.geom, 30), ih.geom) AS geom, 
                       ST_Area(ST_Intersection(ST_Buffer(la.geom, 30), ih.geom)) AS area_m2
                  FROM entrega_XX.lote_atp la
            INNER JOIN iema.hidro ih
                    ON la.geom && ih.geom;

CREATE TABLE entrega_XX.iema_hidro_int AS
      SELECT cod_imovel,
             cod_emp,
             municipio,
             lote,
             ST_Area(ST_Union(iema_hidro_temp.geom)) AS area_m2, 
             ST_Multi(ST_Union(iema_hidro_temp.geom)) AS geom 
        FROM iema_hidro_temp
       WHERE area_m2 > 0
    GROUP BY cod_imovel, cod_emp, municipio, lote;

CREATE TEMPORARY TABLE iema_avn_int_temp AS
                SELECT la.id, 
                       la.cod_imovel,
                       la.cod_emp,
                       la.municipio,
                       la.lote,
                       ST_Intersection(la.geom, iv.geom) AS geom, 
                       ST_Area(ST_Intersection(la.geom, iv.geom)) AS area_m2
                  FROM entrega_XX.lote_atp la
            INNER JOIN iema.avn iv
                    ON la.geom && iv.geom;

CREATE TABLE entrega_XX.iema_avn_int AS
      SELECT cod_imovel,
             cod_emp,
             municipio,
             lote,
             ST_Area(ST_Union(iema_avn_int_temp.geom)) AS area_m2, 
             ST_Multi(ST_Union(iema_avn_int_temp.geom)) AS geom 
        FROM iema_avn_int_temp
       WHERE area_m2 > 0
    GROUP BY cod_imovel, cod_emp, municipio, lote;
