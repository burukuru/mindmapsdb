/*
 * Grakn - A Distributed Semantic Database
 * Copyright (C) 2016  Grakn Labs Limited
 *
 * Grakn is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * Grakn is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Grakn. If not, see <http://www.gnu.org/licenses/gpl.txt>.
 */

package ai.grakn.engine.controller;

import ai.grakn.GraknGraph;
import ai.grakn.concept.Concept;
import ai.grakn.engine.session.RemoteSession;
import ai.grakn.engine.util.ConfigProperties;
import ai.grakn.exception.GraknEngineServerException;
import ai.grakn.factory.GraphFactory;
import ai.grakn.graql.MatchQuery;
import ai.grakn.graql.Printer;
import ai.grakn.graql.Reasoner;
import ai.grakn.graql.internal.printer.Printers;
import ai.grakn.util.REST;
import io.swagger.annotations.Api;
import io.swagger.annotations.ApiImplicitParam;
import io.swagger.annotations.ApiImplicitParams;
import io.swagger.annotations.ApiOperation;
import org.json.JSONArray;
import org.json.JSONObject;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import spark.Request;
import spark.Response;

import javax.ws.rs.GET;
import javax.ws.rs.Path;
import javax.ws.rs.Produces;
import java.util.stream.Collectors;

import static spark.Spark.get;
import static spark.Spark.webSocket;
import static spark.Spark.webSocketIdleTimeoutMillis;


@Path("/shell")
@Api(value = "/shell", description = "Endpoints to execute match queries and obtain meta-ontology types instances.")
@Produces({"application/json", "text/plain"})

public class RemoteShellController {

    private final Logger LOG = LoggerFactory.getLogger(RemoteShellController.class);
    private final int WEBSOCKET_TIMEOUT = 3600000;


    String defaultGraphName = ConfigProperties.getInstance().getProperty(ConfigProperties.DEFAULT_GRAPH_NAME_PROPERTY);

    public RemoteShellController() {

        webSocket(REST.WebPath.REMOTE_SHELL_URI, RemoteSession.class);
        webSocketIdleTimeoutMillis(WEBSOCKET_TIMEOUT);

        get(REST.WebPath.MATCH_QUERY_URI, this::matchQuery);
        get(REST.WebPath.META_TYPE_INSTANCES_URI, this::buildMetaTypeInstancesObject);
    }

    @GET
    @Path("/metaTypeInstances")
    @ApiOperation(
            value = "Produces a JSONObject containing meta-ontology types instances.",
            notes = "The built JSONObject will contain ontology nodes divided in roles, entities, relations and resources.",
            response = JSONObject.class)
    @ApiImplicitParam(name = "graphName", value = "Name of graph tu use", dataType = "string", paramType = "query")


    private String buildMetaTypeInstancesObject(Request req, Response res) {

        String currentGraphName = req.queryParams(REST.Request.GRAPH_NAME_PARAM);
        if (currentGraphName == null) currentGraphName = defaultGraphName;

        try(GraknGraph graph = GraphFactory.getInstance().getGraph(currentGraphName)){
            JSONObject responseObj = new JSONObject();
            responseObj.put(REST.Response.ROLES_JSON_FIELD, new JSONArray(graph.getMetaRoleType().instances().stream().map(Concept::getId).toArray()));
            responseObj.put(REST.Response.ENTITIES_JSON_FIELD, new JSONArray(graph.getMetaEntityType().instances().stream().map(Concept::getId).toArray()));
            responseObj.put(REST.Response.RELATIONS_JSON_FIELD, new JSONArray(graph.getMetaRelationType().instances().stream().map(Concept::getId).toArray()));
            responseObj.put(REST.Response.RESOURCES_JSON_FIELD, new JSONArray(graph.getMetaResourceType().instances().stream().map(Concept::getId).toArray()));

            return responseObj.toString();
        } catch (Exception e) {
            throw new GraknEngineServerException(500, e);
        }
    }

    @GET
    @Path("/match")
    @ApiOperation(
            value = "Executes match query on the server and produces a result string.")
    @ApiImplicitParams({
            @ApiImplicitParam(name = "graphName", value = "Name of graph to use", dataType = "string", paramType = "query"),
            @ApiImplicitParam(name = "query", value = "Match query to execute", required = true, dataType = "string", paramType = "query")
    })
    private String matchQuery(Request req, Response res) {

        String currentGraphName = req.queryParams(REST.Request.GRAPH_NAME_PARAM);
        if (currentGraphName == null) currentGraphName = defaultGraphName;

        LOG.debug("Received match query: \"" + req.queryParams(REST.Request.QUERY_FIELD) + "\"");

        Printer printer = Printers.graql();

        try(GraknGraph graph = GraphFactory.getInstance().getGraph(currentGraphName)) {
            MatchQuery matchQuery = graph.graql().parse(req.queryParams(REST.Request.QUERY_FIELD));
            MatchQuery inferQuery = new Reasoner(graph).resolveToQuery(matchQuery);
            return inferQuery
                    .resultsString(printer)
                    .map(x -> x.replaceAll("\u001B\\[\\d+[m]", ""))
                    .collect(Collectors.joining("\n"));
        } catch (Exception e) {
            throw new GraknEngineServerException(500,e);
        }
    }


}