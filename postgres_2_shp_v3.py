#from qgis.core import QgsVectorLayer, QgsDataSourceUri
import os
from zipfile import ZipFile
from shutil import copyfile



#refresh canvas
QgsProject.instance().clear()

project = QgsProject.instance()

schema = "entrega_04"
test_style = {'color_border':'#FF0000', 'width_border':'.8', 'style':'no'}

#lista com as tabelas da base de dados e definição de estilo de cada camada
tables = {
         "base_atp":{'color':'#707070', 'color_border':'#000000','outline_style':'dash'},
         "base_arl":{'color': '#8a8a8a','color_border':'#8a8a8a', 'style':'b_diagonal'},
         "lote_atp":{'color_border':'#ffd75e','width_border':'.8','style':'no'},
         "lote_aa":{'color': '#fff696','color_border':'#000000','outline_style':'no'},
         "lote_avn":{'color': '#165e1f','color_border':'#000000'},
         "lote_hidro":{'color': '#00fff7','color_border':'#0000fc'},
         "lote_app":{'color': '#ff0000', 'color_border':'#000000'},
         "lote_arl":{'color': '#000000', 'color_border':'#000000', 'style':'f_diagonal'},
         "teste_01":test_style, "teste_02":test_style, "teste_03":test_style,
         "teste_04":test_style, "teste_05":test_style, "teste_06":test_style,
         "teste_07":test_style, "teste_08":test_style, "teste_09":test_style,
         "teste_10":test_style, "teste_11":test_style, "teste_12":test_style
         }

#conecta à bd do postgres e adiciona camadas ao mapa com o respectivo estilo
for table in tables:
    uri = QgsDataSourceUri()
    uri.setConnection("localhost", "5432", "idaf", "postgres", "048162")
    uri.setDataSource (schema, table, "geom")
    lyr = QgsVectorLayer(uri.uri(), table, "postgres")

    if not lyr.isValid():
        print("Layer {} não é válida!".format(table))

    else:
        symbol_style = tables[table]
        symbol = QgsFillSymbol.createSimple(symbol_style)
        lyr.renderer().setSymbol(symbol)
        lyr.setOpacity(.5)
        project.instance().addMapLayer(lyr)

def get_lst_reprovado(layer, teste):
    """
    função auxiliar que retorna lista dos imoveis reprovados no teste escolhido
    """
    lst_reprovado = []
    for feat in layer.getFeatures():
        if feat[teste]:
            lst_reprovado.append(feat['cod_emp'])
    return(lst_reprovado)

def update_fields(path):
    """
    função auxiliar que atualiza tabela de atributos da atp, removendo colunas
    dos testes que não precisam ser revistos
    """
    atp = QgsVectorLayer(path, 'atp', 'ogr')

    features = atp.getFeatures()

    # Fields to delete
    del_ids = []
    del_names = set(['lote', 'geral', 'doc_cadast', 'num_solici', 
    'mes_envio', 'ano_envio', 'requerimen', 'stat_simla', 'stat_sicar'])
    #Fields to update
    up_ids = []
    up_names = set([])
    for feat in features:
        for fld in atp.fields():
            if 'teste' in fld.name():
                if not feat[fld.name()]:
                    del_names.add(fld.name())
                else:
                    up_names.add(fld.name())
                    
            if fld.name() in del_names:
                del_ids.append(feat.fieldNameIndex(fld.name()))
            elif fld.name() in up_names:
                del_ids.append(feat.fieldNameIndex(fld.name()))
                
    atp.dataProvider().deleteAttributes(del_ids)

    for name in up_names:
        atp.dataProvider().addAttributes([QgsField(name, QVariant.String)])
    atp.updateFields()
    
#funções principais
def gen_dir(layer, teste, root_folder):
    """
    cria pastas para imoveis reprovados em determinado teste
    """
    lyr = project.mapLayersByName(layer)[0]
    selection = get_lst_reprovado(lyr, teste)
    features = lyr.getFeatures()
    root_path = 'C:/' + root_folder + '_shp_result'

    os.mkdir(root_path)
    
    for feat in features:
        lote = feat['lote']
        municipio = feat['municipio']
        cod_emp = feat['cod_emp']
        lote_path = root_path + '/' + lote
        mun_path = lote_path + '/' + municipio
        imovel_path = mun_path + '/' + cod_emp
        
        if cod_emp in selection:
            if not os.path.exists(lote_path):
                os.makedirs(lote_path)
            
            if not os.path.exists(mun_path):
                os.makedirs(mun_path)
                
            os.mkdir(imovel_path)
            os.mkdir(imovel_path + '/shapefiles')

def gen_shapefile_imovel(layer, root_folder):
    """
    gera shapefile das feições do tipo lote reprovadas no referido teste
    agrupadas por código do imóvel
    """
    atp = project.mapLayersByName('lote_atp')[0]
    selection = get_lst_reprovado(atp, 'geral')
    lyr = project.mapLayersByName(layer)[0]
    features = lyr.getFeatures()
    root_path = 'C:/' + root_folder + '_shp_result'
    for feat in features:
        lote = feat['lote']
        mun = feat['municipio']
        cod_emp = feat['cod_emp']
        path = 'C:/' + root_folder + '_shp_result/' + lote + '/' + mun  + '/' + cod_emp + '/shapefiles/'
        
        if cod_emp in selection:
            fid = feat.id()
            lyr.select(fid)
            file_name = path + layer[5:] + '.shp'
            writer = QgsVectorFileWriter.writeAsVectorFormat(lyr, file_name, \
            'utf-8', driverName = 'ESRI Shapefile', onlySelected=True)
            del(writer)
            lyr.removeSelection()
            if layer == 'lote_atp':
                update_fields(file_name)

def gen_shapefile_teste(layer, root_folder):
    """
    gera shapefile das feições do tipo teste agrupadas por código do imóvel
    imprime mensagem caso não haja feições no teste selecionado
    """
    #gera shapefile das camadas do tipo teste
    try:
        lyr = project.mapLayersByName(layer)[0]
        features = lyr.getFeatures()
        root_path = 'C:/' + root_folder + '_shp_result/'
        for feat in features:
            fid = feat.id()
            lote = feat['lote']
            mun = feat['municipio']
            cod_emp = feat['cod_emp']
            path = root_path + lote + '/' + mun  + '/' + cod_emp + '/shapefiles/'
            lyr.select(fid)
            file_name = path + layer + '.shp'
            writer = QgsVectorFileWriter.writeAsVectorFormat(lyr, file_name, \
            'utf-8', driverName = 'ESRI Shapefile', onlySelected=True)
            del(writer)
            lyr.removeSelection()
    except:
        print("Nenhum shapefile gerado para {}".format(table))

def gen_shapefile_base(layer, root_folder):
    """
    gera shapefile das camadas do tipo base, agrupadas por código do imóvel
    do lote com a qual se sobrepõem
    imprime mensagem caso não haja feições na base selecionada
    """
    try:
        lyr = project.mapLayersByName(layer)[0]
        features = lyr.getFeatures()
        root_path = 'C:/' + root_folder + '_shp_result/'
        for feat in features:
            fid = feat.id()
            lote = feat['lote']
            mun = feat['municipio']
            cod_emp = feat['cod_emp_lote']
            lyr.select(fid)
            path = root_path + lote + '/' + mun  + '/' + cod_emp + '/shapefiles/'
            file_name = path + layer + '.shp'
            writer = QgsVectorFileWriter.writeAsVectorFormat(lyr, file_name, \
            'utf-8', driverName = 'ESRI Shapefile', onlySelected=True)
            del(writer)
            lyr.removeSelection()
    except:
        print("Nenhum shapefile gerado para {}".format(table))
        
def gen_qgz(layer, teste, root_folder, src):
    """
    cria arquivo .qgz padrão para imoveis reprovados em determinado teste
    """
    lyr = project.mapLayersByName(layer)[0]
    selection = get_lst_reprovado(lyr, teste)
    features = lyr.getFeatures()
    root_path = 'C:/' + root_folder
    for feat in features:
        lote = feat['lote']
        mun = feat['municipio']
        cod_emp = feat['cod_emp']
        path = 'C:/' + root_folder + '_shp_result/' + lote + '/' + mun  + '/' + cod_emp
        if cod_emp in selection:
            dst = path + '/projeto.qgz'
            copyfile(src, dst)

def zip(src, dst):
    dest_name = dest+source[19:]+'.zip'
    zf = zipfile.ZipFile(dest_name, "w", zipfile.ZIP_DEFLATED)
    abs_src = os.path.abspath(src)
    for dirname, subdirs, files in os.walk(src):
        for filename in files:
            absname = os.path.abspath(os.path.join(dirname, filename))
            arcname = absname[len(abs_src) + 1:]
            zf.write(absname, arcname)
    zf.close()
    print('{} zipado com sucesso!'.format(dir))
"""
#cria pasta para os imóveis que tenham reprovado em ao menos um teste
gen_dir('lote_atp', 'geral', schema)

#copia o template modelo do qgis para a pasta de cada imóvel
source = 'C:/projeto_padrao.qgz'
gen_qgz('lote_atp', 'geral', schema, source)

#itera a lista de tabelas para gerar os shapefiles
for table in tables:
    if 'lote' in table:
        gen_shapefile_imovel(table, schema)
    elif 'teste' in table:
        gen_shapefile_teste(table, schema)
    elif 'base' in table:
        gen_shapefile_base(table, schema)
"""

