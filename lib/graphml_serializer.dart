import 'package:flutter/material.dart';
import 'package:flutter_provider_canvas/model/canvas_model.dart';
import 'package:flutter_provider_canvas/model/component_data.dart';
import 'package:flutter_provider_canvas/model/link_data.dart';
import 'package:flutter_provider_canvas/model/port_data.dart';
import 'package:xml/xml.dart';

// source: https://cs.brown.edu/people/rtamassi/gdhandbook/chapters/graphml.pdf

class GraphmlSerializer {
  static XmlDocument buildDiagramXml(CanvasModel model) {
    final builder = XmlBuilder();
    builder.processing('xml', 'version="1.0"');

    builder.element('graphml', nest: () {
      builder.attribute('xmlns', 'http://graphml.graphdrawing.org/xmlns');
      builder.attribute(
          'xmlns:xsi', 'http://www.w3.org/2001/XMLSchema-instance');
      builder.attribute('xsi:schemaLocation',
          'http://graphml.graphdrawing.org/xmlns http://graphml.graphdrawing.org/xmlns/1.0/graphml.xsd');

      _buildExtraData(builder);

      builder.element('graph', nest: () {
        builder.attribute('id', 'G');
        builder.attribute('edgedefault', 'directed');
        _buildGraphData(builder, model);

        _buildNodes(builder, model);
        _buildEdges(builder, model);
      });
    });

    return builder.buildDocument();
  }

  static _buildExtraData(XmlBuilder builder) {
    // node:
    _buildData(builder, 'd0', 'node', 'double', 'position.dx');
    _buildData(builder, 'd1', 'node', 'double', 'position.dy');
    _buildData(builder, 'd2', 'node', 'double', 'size.width');
    _buildData(builder, 'd3', 'node', 'double', 'size.height');
    _buildData(builder, 'd4', 'node', 'double', 'minSize.width');
    _buildData(builder, 'd5', 'node', 'double', 'minSize.height');
    _buildData(builder, 'd6', 'node', 'double', 'portSize');
    _buildData(builder, 'd7', 'node', 'string', 'optionsData');
    _buildData(builder, 'd8', 'node', 'string', 'customData');
    _buildData(builder, 'd9', 'node', 'string', 'componentBodyName');
    // port:
    _buildData(builder, 'd10', 'port', 'int', 'color');
    _buildData(builder, 'd11', 'port', 'int', 'borderColor');
    _buildData(builder, 'd12', 'port', 'double', 'alignment.x');
    _buildData(builder, 'd13', 'port', 'double', 'alignment.y');
    _buildData(builder, 'd14', 'port', 'string', 'portType');
    // edge:
    _buildData(builder, 'd15', 'edge', 'int', 'color');
    _buildData(builder, 'd16', 'edge', 'double', 'width');
    _buildData(builder, 'd17', 'edge', 'double', 'tipSize');
    _buildData(builder, 'd18', 'edge', 'string', 'linkPoints');
  }

  static _buildData(
    XmlBuilder builder,
    String id,
    String forElement, [
    String attributeType,
    String attributeName,
    String defaultValue,
  ]) {
    builder.element('key', nest: () {
      builder.attribute('id', id);
      builder.attribute('for', forElement);
      builder.attribute('attr.type', attributeType);
      builder.attribute('attr.name', attributeName);
      if (defaultValue != null) {
        builder.element('default', nest: defaultValue);
      }
    });
  }

  static _buildDataInstance(
    XmlBuilder builder,
    String key,
    Object value,
  ) {
    builder.element('data', nest: () {
      builder.attribute('key', key);
      builder.text(value);
    });
  }

  static _buildGraphData(XmlBuilder builder, CanvasModel model) {
    // builder.element('data');
  }

  static _buildNodes(XmlBuilder builder, CanvasModel model) {
    model.componentDataMap.values.forEach((component) {
      _buildNode(builder, component);
    });
  }

  static _buildNode(XmlBuilder builder, ComponentData component) {
    builder.element('node', nest: () {
      builder.attribute('id', component.id);
      component.portList.forEach((port) {
        _buildPort(builder, port);
      });
      _buildNodeData(builder, component);
    });
  }

  static _buildNodeData(XmlBuilder builder, ComponentData component) {
    _buildDataInstance(builder, 'd0', component.position.dx);
    _buildDataInstance(builder, 'd1', component.position.dy);
    _buildDataInstance(builder, 'd2', component.size.width);
    _buildDataInstance(builder, 'd3', component.size.height);
    _buildDataInstance(builder, 'd4', component.minSize.width);
    _buildDataInstance(builder, 'd5', component.minSize.height);
    _buildDataInstance(builder, 'd6', component.portSize);
    _buildDataInstance(builder, 'd7', 'TODO: options data name');
    _buildDataInstance(builder, 'd8', component.customData.serialize());
    _buildDataInstance(builder, 'd9', component.componentBodyName);
  }

  static _buildPort(XmlBuilder builder, PortData port) {
    builder.element('port', nest: () {
      builder.attribute('name', '${port.id}');
      _buildPortData(builder, port);
    });
  }

  static _buildPortData(XmlBuilder builder, PortData port) {
    _buildDataInstance(builder, 'd10', port.color.value);
    _buildDataInstance(builder, 'd11', port.borderColor.value);
    _buildDataInstance(builder, 'd12', port.alignment.x);
    _buildDataInstance(builder, 'd13', port.alignment.y);
    _buildDataInstance(builder, 'd14', port.portType);
  }

  static _buildEdges(XmlBuilder builder, CanvasModel model) {
    model.linkDataMap.values.forEach((link) {
      _buildEdge(
        builder,
        link,
        model.componentDataMap[link.componentOutId].id,
        model.componentDataMap[link.componentInId].id,
      );
    });
  }

  static _buildEdge(
    XmlBuilder builder,
    LinkData link,
    String sourcePort,
    String targetPort,
  ) {
    builder.element('edge', nest: () {
      builder.attribute('id', link.id);

      builder.attribute('source', link.componentOutId);
      builder.attribute('target', link.componentInId);
      builder.attribute('sourceport', sourcePort);
      builder.attribute('targetport', targetPort);

      _buildEdgeData(builder, link);
    });
  }

  static _buildEdgeData(
    XmlBuilder builder,
    LinkData link,
  ) {
    _buildDataInstance(builder, 'd15', link.color.value);
    _buildDataInstance(builder, 'd16', link.width);
    _buildDataInstance(builder, 'd17', link.tipSize);
    _buildDataInstance(builder, 'd18', _linkPointsToString(link.linkPoints));
  }

  static String _linkPointsToString(List<Offset> points) {
    return points.map((p) => '(${p.dx},${p.dy})').reduce((pp, p) => '$pp;$p');
  }
}