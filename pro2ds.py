from datetime import date, timedelta
from lxml import etree
from zipfile import *
import re, os, errno, sys, getopt

destination = '.'
embargo_codes = {'0':None, '1':6, '2':12, '3':24}

# Regex
re_meta = re.compile('_DATA.xml')
re_uri_id = re.compile('.*duke:(?P<id>\d+)')
re_attach = re.compile('.*/.+') #contents of any sub-dirs

# Metadata Transform
xslt_file = open('2dublin_core.xsl')
xslt_doc = etree.parse(xslt_file)
xslt_file.close()
dc_xslt = etree.XSLT(xslt_doc)

embargo_xml_template = """<dublin_core schema="duke">
    <dcvalue element="embargo" qualifier="months">%s</dcvalue>
    <dcvalue element="embargo" qualifier="release">%s</dcvalue>
</dublin_core>"""

def main(argv=None):
    if argv is None:
        argv = sys.argv[1:]
    try:          
        opts, args = getopt.getopt(argv, "d:", ["dest="]) 
    except getopt.GetoptError:
        sys.exit(2)
    for opt, arg in opts:
        if opt in ('-d','--dest'):
            global destination
            destination = arg

    for arg in args:
        if os.path.isdir(arg):
            for f in os.listdir(arg):
                try:
                    convert('/'.join((arg,f)))
                except:
                    print "Could not process %s" % (f)
        else:
            try:
                convert(arg)
            except:
                print "Could not process %s" % (arg)

def convert(diss_zip):
    # open zip (http://docs.python.org/library/zipfile.html)
    zip_obj = ZipFile(diss_zip, 'r')

    # read umi xml
    meta = filter(re_meta.search,zip_obj.namelist())[0]
    meta_file = zip_obj.open(meta, 'r')
    tree = etree.parse(meta_file)
    meta_file.close()

    # create destination directory (ID_name_year?)
    umi_uri = tree.find('//DISS_description').get('external_id')
    m = re_uri_id.match(umi_uri)
    sub_id = m.group('id')
    item_dir_name_parts = [sub_id]
    author_element = tree.find("//DISS_author[@type='primary']/DISS_name")
    item_dir_name_parts.extend(author_element.findtext('DISS_surname').split())
    item_dir_name_parts.extend(author_element.findtext('DISS_fname').split())
    item_dir_name_parts.append(tree.findtext('//DISS_comp_date'))
    item_destination = '/'.join((destination,'_'.join(item_dir_name_parts)))

    try:
        os.makedirs(item_destination)
    except OSError as exc:
        if exc.errno == errno.EEXIST:
            pass
        else:
            print "Cannot create directory for %s : %s" % (diss_zip, exc.errno)
            return
    # for the record
    print '\t'.join((sub_id, author_element.findtext('DISS_surname')))
    
    # create DC
    dc_tree = dc_xslt(tree)
    dc_file = open('/'.join((item_destination,'dublin_core.xml')), 'wb')
    dc_file.write(etree.tostring(dc_tree, pretty_print=True, xml_declaration=True))
    dc_file.close()
    
    # create Embargo
    embargo_code = tree.getroot().get('embargo_code')
    try:
        if embargo_codes[embargo_code]:
            release = date.today()+timedelta(days=embargo_codes[embargo_code]*(365/12))
            embargo_tree = etree.fromstring(embargo_xml_template % (embargo_codes[embargo_code], release.isoformat()))
            embargo_file = open('/'.join((item_destination,'metadata_duke.xml')), 'wb')
            embargo_file.write(etree.tostring(embargo_tree, pretty_print=True, xml_declaration=True))
            embargo_file.close()
    except KeyError as keyerr:
        print "Bad embargo code (%s) in %s" % (embargo_code, diss_zip)
        
    # copy files
    manifest = []
    #dissertation
    pdf = tree.findtext('//DISS_content/DISS_binary[@type="PDF"]')
    f = zip_obj.open(pdf, 'r')
    diss = open ('/'.join((item_destination,pdf)), 'wb')
    diss.write(f.read())
    diss.close
    manifest.append(pdf)
    #attachments
    for name in filter(re_attach.search,zip_obj.namelist()):
        manifest.append(name)
        zip_obj.extract(name,item_destination)
    
    # create contents
    manifest_file = open('/'.join((item_destination,'contents')), 'w')
    manifest_file.write('\n'.join(manifest))
    manifest_file.close()

if __name__ == "__main__":
    main()
