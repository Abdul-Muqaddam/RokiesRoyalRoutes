#!/usr/bin/env python3
import os
import xml.etree.ElementTree as ET

def convert_android_vector_to_svg(xml_file, out_file):
    try:
        tree = ET.parse(xml_file)
        root = tree.getroot()
        
        width = root.attrib.get('{http://schemas.android.com/apk/res/android}viewportWidth', '24')
        height = root.attrib.get('{http://schemas.android.com/apk/res/android}viewportHeight', '24')
        
        svg = ET.Element('svg', {
            'xmlns': 'http://www.w3.org/2000/svg',
            'viewBox': f'0 0 {width} {height}',
            'width': width,
            'height': height
        })
        
        for path in root.findall('path'):
            path_data = path.attrib.get('{http://schemas.android.com/apk/res/android}pathData', '')
            fill_color = path.attrib.get('{http://schemas.android.com/apk/res/android}fillColor', '#000000')
            if len(fill_color) == 9 and fill_color.startswith('#'):
                # Convert #AARRGGBB to #RRGGBB
                fill_color = '#' + fill_color[3:]
            
            ET.SubElement(svg, 'path', {
                'd': path_data,
                'fill': fill_color
            })
            
        tree = ET.ElementTree(svg)
        tree.write(out_file, encoding='utf-8', xml_declaration=True)
        print(f"Converted {xml_file} -> {out_file}")
    except Exception as e:
        print(f"Failed to convert {xml_file}: {e}")

icon_dir = 'assets/icons'
for file in os.listdir(icon_dir):
    if file.endswith('.xml'):
        xml_path = os.path.join(icon_dir, file)
        svg_path = os.path.join(icon_dir, file.replace('.xml', '.svg'))
        convert_android_vector_to_svg(xml_path, svg_path)
        os.remove(xml_path)
